(**************************************************************************)
(*                                                                        *)
(*  This file is part of WP plug-in of Frama-C.                           *)
(*                                                                        *)
(*  Copyright (C) 2007-2012                                               *)
(*    CEA (Commissariat a l'�nergie atomique et aux �nergies              *)
(*         alternatives)                                                  *)
(*                                                                        *)
(*  you can redistribute it and/or modify it under the terms of the GNU   *)
(*  Lesser General Public License as published by the Free Software       *)
(*  Foundation, version 2.1.                                              *)
(*                                                                        *)
(*  It is distributed in the hope that it will be useful,                 *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *)
(*  GNU Lesser General Public License for more details.                   *)
(*                                                                        *)
(*  See the GNU Lesser General Public License version 2.1                 *)
(*  for more details (enclosed in the file licenses/LGPLv2.1).            *)
(*                                                                        *)
(**************************************************************************)

(* -------------------------------------------------------------------------- *)
(* --- Empty Memory Model                                                 --- *)
(* -------------------------------------------------------------------------- *)

open Cil_types
open Cil_datatype
open Ctypes
open Qed
open Lang
open Lang.F
open Memory
open Definitions

let datatype = "MemTyped"
let theory = "memory"

let a_addr = record ~link:"addr" ~theory [ "base" , Logic.Int ; "offset" , Logic.Int ]
let t_addr = Logic.Data(a_addr,[])
let f_base = field a_addr "base"
let f_offset = field a_addr "offset"
let _f_shift = Lang.extern_f ~theory "shift"
let p_valid = Lang.extern_fp ~theory "valid"
let p_separated = Lang.extern_fp ~theory "separated"
let p_included = Lang.extern_fp ~theory "included"
let p_eqmem = Lang.extern_fp ~theory "eqmem"
let p_havoc = Lang.extern_fp ~theory "havoc"
let f_region = Lang.extern_f ~theory ~sort:Logic.Sint "region"   (* base -> region *)
let p_linked = Lang.extern_fp ~theory "linked" (* t-alloc -> prop *)
let p_framed = Lang.extern_fp ~theory "framed" (* m-pointer -> prop *)
let a_lt = Lang.extern_p ~theory ~prop:"addr_lt" ~bool:"addr_lt_bool"
let a_leq = Lang.extern_p ~theory ~prop:"addr_le" ~bool:"addr_le_bool"
let a_cast = Lang.extern_f ~sort:Logic.Sint ~category:Logic.Injection ~theory "cast"
let a_hardware = Lang.extern_f ~sort:Logic.Sint ~category:Logic.Injection ~theory "hardware"

(* -------------------------------------------------------------------------- *)
(* --- Utilities on loc-as-term                                           --- *)
(* -------------------------------------------------------------------------- *)

let a_base l = F.e_getfield l f_base
let a_offset l = F.e_getfield l f_offset
let a_addr base offset = F.e_record [ f_base , base ; f_offset , offset ]
let a_shift l k = 
  if F.is_zero k then l else a_addr (a_base l) (F.e_add (a_offset l) k)
  (* if F.is_zero k then l else F.e_fun f_shift [l;k] *)
let a_null = a_addr e_zero e_zero

(* -------------------------------------------------------------------------- *)
(* --- Model Parameters                                                   --- *)
(* -------------------------------------------------------------------------- *)

let register ~name ?id ?descr ?tuning () =
  let model = Model.register ~name ?id ?descr ?tuning () in
  Model.set_parameter model Lang.pointer (fun _ -> t_addr) "addr" ;
  Model.set_parameter model Cvalues.null (p_equal a_null) "null" ;
  model

type pointer = NoCast | Fits
let pointer = Context.create ~default:NoCast "MemTyped.pointer"
let nocast m = Model.set_parameter m pointer NoCast "No pointer casts"
let fits m = Model.set_parameter m pointer Fits "Casts with fitting pointers"

(* -------------------------------------------------------------------------- *)
(* --- Chunks                                                             --- *)
(* -------------------------------------------------------------------------- *)

type chunk = 
  | M_int
  | M_float
  | M_pointer
  | T_alloc

module Chunk =
struct
  type t = chunk
  let self = "typed"
  let rank = function 
    | M_int -> 0
    | M_float -> 1
    | M_pointer -> 2
    | T_alloc -> 3
  let hash = rank
  let name = function
    | M_int -> "Mint"
    | M_float -> "Mflt"
    | M_pointer -> "Mptr"
    | T_alloc -> "Malloc"
  let compare a b = rank a - rank b
  let equal = (=)
  let pretty fmt c = Format.pp_print_string fmt (name c)
  let key_of_chunk = function
    | M_int | M_float | M_pointer -> t_addr
    | T_alloc -> Logic.Int
  let val_of_chunk = function
    | M_int -> Logic.Int
    | M_float -> Logic.Real
    | M_pointer -> t_addr
    | T_alloc -> Logic.Int
  let tau_of_chunk =
    let m = Array.create 4 Logic.Int in
    List.iter 
      (fun c -> m.(rank c) <- Logic.Array(key_of_chunk c,val_of_chunk c))
      [M_int;M_float;M_pointer;T_alloc] ;
    fun c -> m.(rank c)
  let basename_of_chunk = name
end

module Heap = Qed.Collection.Make(Chunk)
module Sigma = Sigma.Make(Chunk)(Heap)

type loc = term (* of type addr *)

(* -------------------------------------------------------------------------- *)
(* --- Utilities on locations                                             --- *)
(* -------------------------------------------------------------------------- *)

let rec footprint = function
  | C_int _ -> Heap.Set.singleton M_int
  | C_float _ -> Heap.Set.singleton M_float
  | C_pointer _ -> Heap.Set.singleton M_pointer
  | C_array a -> footprint (object_of a.arr_element)
  | C_comp c -> footprint_comp c

and footprint_comp c =
  List.fold_left
    (fun ft f ->
       Heap.Set.union ft (footprint (object_of f.ftype))
    ) Heap.Set.empty c.cfields

let signature ft = 
  let s = Sigma.create () in
  let xs = ref [] in
  let cs = ref [] in
  Heap.Set.iter 
    (fun c -> 
       cs := c :: !cs ;
       xs := (Sigma.get s c) :: !xs ;
    ) ft ; 
  List.rev !xs , List.rev !cs , s

let memories sigma ft = List.map (Sigma.value sigma) ft

let rec size_of_object = function
  | C_int _ | C_float _ | C_pointer _ -> Int64.one
  | C_comp c -> size_of_comp c
  | C_array { arr_flat = Some { arr_size = n } ; arr_element = elt } -> 
      Int64.mul n (size_of_typ elt)
  | C_array _ as a ->
      Wp_parameters.abort ~current:true "Undefined array-size (%a)" 
	Ctypes.pretty a
and size_of_typ t = size_of_object (object_of t)
and size_of_field f = size_of_typ f.ftype
and size_of_comp c = 
  List.fold_left
    (fun s f -> Int64.add s (size_of_field f))
    Int64.zero c.cfields

let offset_of_field f =
  let rec fnext k f = function
    | [] -> assert false
    | g::gs ->
	if Fieldinfo.equal f g then k 
	else fnext (Int64.add k (size_of_field f)) f gs
  in fnext Int64.zero f f.fcomp.cfields

(* -------------------------------------------------------------------------- *)
(* --- Utilities on loc-as-term                                           --- *)
(* -------------------------------------------------------------------------- *)

type sigma = Sigma.t
type segment = loc rloc

let pretty fmt l = F.pp_term fmt l
let vars l = F.vars l
let occurs x l = F.occurs x l

(* -------------------------------------------------------------------------- *)
(* --- Basic Manipulation                                                 --- *)
(* -------------------------------------------------------------------------- *)

let loadrec = ref (fun _ _ _ -> assert false)
let field l f = a_shift l (F.e_int64 (offset_of_field f))
let shift l obj k = a_shift l (F.e_mul (F.e_int64 (size_of_object obj)) k)

(* -------------------------------------------------------------------------- *)
(* --- Generated Axiomatization                                           --- *)
(* -------------------------------------------------------------------------- *)

let cluster_globals () = 
  Definitions.cluster ~id:"Globals" ~title:"Global Variables" ()

let cluster_memory () = 
  Definitions.cluster ~id:"Compound" ~title:"Memory Compound Updates" ()

module BASE = Model.Generator(Varinfo)
  (struct
     let name = "MemTyped.BASE"
     type key = varinfo
     type data = term

     let region lfun x base =
       let name = Fun.id lfun ^ "_region" in
       let re = if x.vglob then 0 else if x.vformal then 1 else 2 in
       Definitions.define_lemma {
	 l_assumed = true ;
	 l_name = name ; l_types = 0 ; l_triggers = [] ; l_forall = [] ;
	 l_lemma = p_equal (e_fun f_region [base]) (e_int re) ;
	 l_cluster = cluster_globals () ;
       }

     let linked lfun x base =
       let name = Fun.id lfun ^ "_linked" in
       let size = Ctypes.sizeof_typ x.vtype in
       let a = Lang.freshvar ~basename:"alloc" (Chunk.tau_of_chunk T_alloc) in
       let m = e_var a in
       let m_linked = p_call p_linked [m] in
       let base_size = p_equal (F.e_get m base) (e_int64 size) in
       Definitions.define_lemma {
	 l_assumed = true ;
	 l_name = name ; l_types = 0 ; 
	 l_triggers = [] ; l_forall = [] ;
	 l_lemma = p_forall [a] (p_imply m_linked base_size) ;
	 l_cluster = cluster_globals () ;
       }

     let generate x = 
       let prefix = if x.vglob then "G" else if x.vformal then "P" else "L" in
       let lfun = Lang.generated_f 
	 ~category:Logic.Constructor ~sort:Logic.Sint 
	 "%s_%s_%d" prefix x.vorig_name x.vid in
       let dfun = Definitions.Value( Logic.Int , Def , e_int (succ x.vid) ) in
       Definitions.define_symbol {
	 d_lfun = lfun ; d_types = 0 ; d_params = [] ; d_definition = dfun ;
	 d_cluster = cluster_globals () ;
       } ; 
       let base = e_fun lfun [] in
       region lfun x base ; linked lfun x base ; base

     let compile = Lang.local generate
   end)

module MONOTONIC : 
sig 
  val generate : lfun -> var list -> chunk list -> (term list -> term) -> unit 
end =
struct
  
  type env = {
    lfun : lfun ;
    sigma : sigma ;
    vars : var list ;
    params : term list ;
    range : term ;
    chunks : chunk list ;
    memories : term list ;
  }

  let _cluster () = Definitions.cluster ~id:"TypedMemory" ()
    (* projectified *)

  let update env c m  = 
    List.map 
      (fun c' ->
	 if Chunk.equal c c' then m else Sigma.value env.sigma c'
      ) env.chunks

  let separated env q k = F.p_call p_separated [q;k;List.hd env.params;env.range]
  let included env q k = F.p_call p_included [q;k;List.hd env.params;env.range]

  let generate_update env c =
    let name = Lang.Fun.id env.lfun ^ "_update_" ^ Chunk.name c in
    let q = e_var (Lang.freshvar ~basename:"q" (Chunk.key_of_chunk c)) in
    let v = e_var (Lang.freshvar ~basename:"v" (Chunk.val_of_chunk c)) in
    let phi = e_fun env.lfun (env.params @ env.memories) in
    let mem' = e_set (Sigma.value env.sigma c) q v in
    let phi' = e_fun env.lfun (env.params @ update env c mem') in
    let lemma = p_imply (separated env q e_one) (p_equal phi' phi) in
    Definitions.define_lemma {
      l_assumed = true ;
      l_name = name ; l_types = 0 ;
      l_triggers = [[Trigger.of_term phi']] ;
      l_forall = Vars.elements (F.varsp lemma) ;
      l_lemma = lemma ;
      l_cluster = cluster_memory () ;
    }

  let generate_eqmem env c =
    let name = Lang.Fun.id env.lfun ^ "_eqmem_" ^ Chunk.name c in
    let q = e_var (Lang.freshvar ~basename:"q" (Chunk.key_of_chunk c)) in
    let k = e_var (Lang.freshvar ~basename:"k" Logic.Int) in
    let phi = e_fun env.lfun (env.params @ env.memories) in
    let mem = Sigma.value env.sigma c in
    let mem' = e_var (Lang.freshen (Sigma.get env.sigma c)) in
    let phi' = e_fun env.lfun (env.params @ update env c mem') in
    let eqmem = F.p_call p_eqmem [mem;mem';q;k] in
    let lemma = p_hyps [separated env q k;eqmem] (p_equal phi' phi) in
    Definitions.define_lemma {
      l_assumed = true ;
      l_name = name ; l_types = 0 ;
      l_triggers = [
	[Trigger.of_pred eqmem ; Trigger.of_term phi ] ;
	[Trigger.of_pred eqmem ; Trigger.of_term phi'] ;
      ] ;
      l_forall = Vars.elements (F.varsp lemma) ;
      l_lemma = lemma ;
      l_cluster = cluster_memory () ;
    }
    
  let generate_havoc env c =
    let name = Lang.Fun.id env.lfun ^ "_havoc_" ^ Chunk.name c in
    let q = e_var (Lang.freshvar ~basename:"q" (Chunk.key_of_chunk c)) in
    let k = e_var (Lang.freshvar ~basename:"k" Logic.Int) in
    let phi = e_fun env.lfun (env.params @ env.memories) in
    let mem = Sigma.value env.sigma c in
    let mem' = e_var (Lang.freshen (Sigma.get env.sigma c)) in
    let phi' = e_fun env.lfun (env.params @ update env c mem') in
    let havoc = F.p_call p_havoc [mem;mem';q;k] in
    let lemma = p_hyps [included env q k;havoc] (p_equal phi' phi) in
    Definitions.define_lemma {
      l_assumed = true ;
      l_name = name ; l_types = 0 ;
      l_triggers = [
	[ Trigger.of_pred havoc ; Trigger.of_term phi ] ;	
	[ Trigger.of_pred havoc ; Trigger.of_term phi'] ;
      ] ;
      l_forall = Vars.elements (F.varsp lemma) ;
      l_lemma = lemma ;
      l_cluster = cluster_memory () ;
    }

  let generate lfun xs cs range =
    let sigma = Sigma.create () in
    let xp = Lang.freshvar ~basename:"p" t_addr in
    let xs = List.map Lang.freshen xs in
    let ps = List.map e_var xs in
    let ms = memories sigma cs in
    let env = {
      sigma = sigma ; lfun = lfun ;
      vars = xp::xs ; params = e_var xp::ps ;
      chunks = cs ; memories = ms ;
      range = range ps ;
    } in
    List.iter 
      (fun chunk ->
	 generate_update env chunk ;
	 generate_eqmem env chunk ;
	 generate_havoc env chunk ;
      ) cs

end

module COMP = Model.Generator(Compinfo)
  (struct
     let name = "MemTyped.COMP"
     type key = compinfo
     type data = lfun * chunk list

     let generate c =
       let lfun = Lang.generated_f "Load_%s" (Lang.comp_id c) in
       let xmem,ft,sigma = signature (footprint_comp c) in
       let xloc = Lang.freshvar ~basename:"p" t_addr in
       let loc = e_var xloc in
       let def = List.map
	 (fun f ->
	    Cfield f , !loadrec sigma (object_of f.ftype) (field loc f)
	 ) c.cfields in
       let dfun = Definitions.Value( Lang.tau_of_comp c , Def , e_record def ) in
       Definitions.define_symbol {
	 d_lfun = lfun ; d_types = 0 ;
	 d_params = xloc :: xmem ;
	 d_definition = dfun ;
	 d_cluster = cluster_memory () ;
       } ; 
       let range = e_int64 (size_of_comp c) in
       MONOTONIC.generate lfun [] ft (fun _ -> range) ;
       lfun , ft

     let compile = Lang.local generate
   end)

module ARRAY = Model.Generator(Matrix.NATURAL)
  (struct
     open Matrix
     let name = "MemTyped.ARRAY"
     type key = matrix
     type data = lfun * chunk list

     let generate (obj,ds) =
       let lfun = Lang.generated_f "Array%s_%s" 
	 (Matrix.id ds) (Matrix.natural_id obj) 
       in
       let axiom = Fun.id lfun ^ "_access" in
       let xmem,ft,sigma = signature (footprint obj) in
       let xloc = Lang.freshvar ~basename:"p" t_addr in
       let loc = e_var xloc in
       let denv = Matrix.denv ds in
       let phi = e_fun lfun (loc :: denv.size_val @ List.map e_var xmem) in
       let arr = List.fold_left e_get phi denv.index_val in
       let elt = !loadrec sigma obj (shift loc obj (e_sum denv.index_offset)) in
       let lemma = p_hyps denv.index_range (p_equal arr elt) in
       let cluster = cluster_memory () in
       Definitions.define_symbol {
	 d_lfun = lfun ; d_types = 0 ; 
	 d_params = xloc :: denv.size_var @ xmem ;
	 d_definition = Logic (Matrix.tau obj ds) ;
	 d_cluster = cluster ;
       } ;
       Definitions.define_lemma {
	 l_assumed = true ;
	 l_name = axiom ; l_types = 0 ;
	 l_forall = Vars.elements (F.varsp lemma) ;
	 l_triggers = [[Trigger.of_term arr]] ;
	 l_lemma = lemma ;
	 l_cluster = cluster ;
       } ;
       if denv.monotonic then 
	 MONOTONIC.generate lfun denv.size_var ft F.e_prod ;
       lfun , ft

     let compile = Lang.local generate
   end)

(* -------------------------------------------------------------------------- *)
(* --- Loading Elementary Values                                          --- *)
(* -------------------------------------------------------------------------- *)

let loadvalue sigma obj l = match obj with
  | C_int _ -> F.e_get (Sigma.value sigma M_int) l
  | C_float _ -> F.e_get (Sigma.value sigma M_float) l
  | C_pointer _ -> F.e_get (Sigma.value sigma M_pointer) l
  | C_comp c -> 
      let phi,cs = COMP.get c in 
      e_fun phi (l :: memories sigma cs)
  | C_array a -> 
      let m = Matrix.of_array a in
      let phi,cs = ARRAY.get m in
      e_fun phi ( l :: Matrix.size m @ memories sigma cs )

let () = loadrec := loadvalue

let load sigma obj l = Val (loadvalue sigma obj l)

(* -------------------------------------------------------------------------- *)
(* --- Locations                                                          --- *)
(* -------------------------------------------------------------------------- *)

let null = a_null
let cvar x = a_addr (BASE.get x) e_zero
let pointer_loc t = t
let pointer_val t = t

let get_alloc sigma l = F.e_get (Sigma.value sigma T_alloc) (a_base l)
let get_last sigma l = e_add (get_alloc sigma l) e_minus_one

let base_addr l = a_addr (a_base l) e_zero
let block_length sigma obj l = 
  e_fact (Ctypes.sizeof_object obj) (get_alloc sigma l)

(* -------------------------------------------------------------------------- *)
(* --- Cast                                                               --- *)
(* -------------------------------------------------------------------------- *)

module Layout =
struct

  type atom = P of typ | I of c_int | F of c_float

  let pp_atom fmt = function
    | P ty -> !Ast_printer.d_type fmt (TPtr(ty,[]))
    | I i -> Ctypes.pp_int fmt i
    | F f -> Ctypes.pp_float fmt f

  let is_one n = (Int64.compare n Int64.one = 0)

  let rfits = ref (fun _ _ -> assert false)
    
  let eqatom a1 a2 =
    match a1 , a2 with
      | P t1 , P t2 -> !rfits (Ctypes.object_of t1) (Ctypes.object_of t2)
      | _ -> (a1 = a2)

  type block = 
    | Str of atom * int64
    | Arr of layout * int64 (* non-homogeneous, more than one *)
    | Garbled

  and layout = block list

  let rec pp_block fmt = function
    | Str(a,n) when is_one n -> pp_atom fmt a
    | Str(a,n) -> Format.fprintf fmt "%a[%s]" pp_atom a (Int64.to_string n)
    | Arr(ly,n) -> Format.fprintf fmt "%a[%s]" pp_layout ly (Int64.to_string n)
    | Garbled -> Format.fprintf fmt "..."
	
  and pp_layout fmt = function
    | [b] -> pp_block fmt b
    | bs ->
	begin
	  Format.fprintf fmt "@[<hov 2>{" ;
	  List.iter (fun b -> Format.fprintf fmt "@ %a" pp_block b) bs ;
	  Format.fprintf fmt " }@]" ;
	end

  let add_atom a ly =
    match ly with
      | Str(b,m) :: w when eqatom a b -> Str(b,Int64.succ m)::w
      | _ -> Str(a,Int64.one) :: ly
	  
  let add_block p ly =
    match p , ly with
      | Str(a,n) , Str(b,m)::w when eqatom a b -> Str(b,Int64.add n m)::w
      | Garbled , Garbled::_ -> ly
      | _ -> p :: ly

  (* requires n > 1 *)
  let add_many ly n w =
    match ly with
      | [] -> w
      | [Str(a,m)] -> add_block (Str(a,Int64.mul m n)) w
      | Garbled::_ -> add_block Garbled w
      | ly -> Arr(ly,n) :: w

  let rec rlayout w = function
    | C_int i -> add_atom (I i) w
    | C_float f -> add_atom (F f) w
    | C_pointer t -> add_atom (P t) w
    | C_comp c -> 
	if c.cstruct 
	then List.fold_left flayout w c.cfields
	else 
	  (* TODO: can be the longuest common prefix *)
	  add_block Garbled w
    | C_array { arr_flat = Some a } ->
	let ly = rlayout [] (Ctypes.object_of a.arr_cell) in
	if is_one a.arr_cell_nbr 
	then ly @ w (* ly is in reversed order *)
	else add_many (List.rev ly) a.arr_cell_nbr w
    | C_array { arr_element = e } ->
	if Wp_parameters.ExternArrays.get () then
	  let ly = rlayout [] (Ctypes.object_of e) in
	  add_many (List.rev ly) Int64.max_int w
	else
	  add_block Garbled w

  and flayout w f = rlayout w (Ctypes.object_of f.ftype)

  type comparison = Fits | Equal | Mismatch

  let add_array ly n w = 
    if is_one n then ly @ w else add_many ly n w

  let rec compare l1 l2 =
    match l1 , l2 with
      | [] , [] -> Equal
      | [] , _ -> Fits
      | _ , [] -> Mismatch
      | p::w1 , q::w2 ->
	  match p , q with
	    | Garbled , _ | _ , Garbled -> Mismatch
	    | Str(a,n) , Str(b,m) -> 
		if eqatom a b then
		  let cmp = Int64.compare n m in
		  if cmp < 0 then
		    (* n < m *)
		    let w2 = Str(a,Int64.sub m n)::w2 in
		    compare w1 w2
		  else if cmp > 0 then
		    (* n > m *)
		    let w1 = Str(a,Int64.sub n m)::w1 in
		    compare w1 w2
		  else
		    (* n = m *)
		    compare w1 w2
		else Mismatch
	    | Arr(u,n) , Arr(v,m) ->
		begin
		  match compare u v with
		    | Mismatch -> Mismatch
		    | Fits -> 
			if is_one n then Fits else Mismatch
		    | Equal ->
			let cmp = Int64.compare n m in
			if cmp < 0 then
			  (* n < m *)
			  let w2 = add_array v (Int64.sub m n) w2 in
			  compare w1 w2
			else if cmp > 0 then
			  (* n > m *)
			  let w1 = add_array u (Int64.sub n m) w1 in
			  compare w1 w2
			else
			  (* n = m *)
			  compare w1 w2
		end
	    | Arr(v,n) , Str _ ->
		compare (v @ add_array v (Int64.pred n) w1) l2
	    | Str _ , Arr(v,n) ->
		compare l1 (v @ add_array v (Int64.pred n) w2)

  let layout obj = List.rev (rlayout [] obj)

  let fits obj1 obj2 = 
    match compare (layout obj1) (layout obj2) with
      | Equal | Fits -> true
      | Mismatch -> false

  let () = rfits := fits

  let rec pretty fmt = function
    | C_pointer ty -> Format.fprintf fmt "%a*" pretty (Ctypes.object_of ty)
    | obj -> pp_layout fmt (layout obj)

end

let cast s l = if F.is_zero l then null else
  if Context.get pointer = Fits && Layout.fits s.post s.pre then l 
  else
    if Context.get pointer = Fits && Wp_parameters.has_dkey "layout" 
    then
      Warning.error ~source:"Typed Model"
	"Cast with incompatible pointers types@\n\
               @[@[Source: %a*@]@ @[(layout: %a)@]@]@\n\
               @[@[Target: %a*@]@ @[(layout: %a)@]@]"
	Ctypes.pretty s.pre Layout.pretty s.pre
	Ctypes.pretty s.post Layout.pretty s.post
    else
      Warning.error ~source:"Typed Model"
	"@[Cast with incompatible pointers types\
               @ (source: %a*)@ (target: %a*)@]"
	Ctypes.pretty s.pre Ctypes.pretty s.post
	
let loc_of_int _ v =
  match F.repr v with
    | Logic.Kint _ -> a_addr e_zero (e_fun a_hardware [v])
    | _ -> Warning.error ~source:"Typed Model" "Forbidden cast of int to pointer"

let int_of_loc _i loc = e_fun a_cast [pointer_val loc]

(* -------------------------------------------------------------------------- *)
(* --- Updates                                                            --- *)
(* -------------------------------------------------------------------------- *)

let domain obj _l = footprint obj

let updated s c l v =
  let m1 = Sigma.value s.pre c in
  let m2 = Sigma.value s.post c in
  [p_equal m2 (F.e_set m1 l v)]

let havoc_range s obj l n =
  let ps = ref [] in
  Heap.Set.iter
    (fun c ->
       let m1 = Sigma.value s.pre c in
       let m2 = Sigma.value s.post c in
       ps := F.p_call p_havoc [m1;m2;l;n] :: !ps
    ) (footprint obj) ; !ps

let havoc s obj l = havoc_range s obj l (e_int64 (size_of_object obj))

let eqmem s obj l = 
  let ps = ref [] in
  let n = e_int64 (size_of_object obj) in
  Heap.Set.iter
    (fun c ->
       let m1 = Sigma.value s.pre c in
       let m2 = Sigma.value s.post c in
       if m1 != m2 then
	 ps := F.p_call p_eqmem [m1;m2;l;n] :: !ps
    ) (footprint obj) ; !ps

(* -------------------------------------------------------------------------- *)
(* --- Copy                                                               --- *)
(* -------------------------------------------------------------------------- *)

let stored s obj l v =
  match obj with
    | C_int _ -> updated s M_int l v
    | C_float _ -> updated s M_float l v
    | C_pointer _ -> updated s M_pointer l v
    | C_comp _ | C_array _ ->
	p_equal (loadvalue s.post obj l) v :: havoc s obj l

let copied s obj p q = stored s obj p (loadvalue s.pre obj q)

(* -------------------------------------------------------------------------- *)
(* --- Assignation                                                        --- *)
(* -------------------------------------------------------------------------- *)

let assigned_loc s obj l =
  match obj with
    | C_int _ | C_float _ | C_pointer _ ->
	let x = Lang.freshvar ~basename:"v" (Lang.tau_of_object obj) in
	stored s obj l (e_var x)
    | C_comp _ | C_array _ -> havoc s obj l

let equal_loc s obj l =
  match obj with
    | C_int _ | C_float _ | C_pointer _ -> 
	[p_equal (loadvalue s.pre obj l) (loadvalue s.post obj l)]
    | C_comp _ | C_array _ -> eqmem s obj l

let assigned_range s obj l a b =
  let l = shift l obj a in
  let n = e_fact (size_of_object obj) (e_range a b) in
  havoc_range s obj l n

let assigned s obj = function
  | Sloc l -> assigned_loc s obj l
  | Sdescr(xs,l,p) ->
      let hs = equal_loc s obj l in
      List.map (fun h -> p_forall xs (p_or p h)) hs
  | Srange(l,obj,u,v) -> 
      let a = match u with Some a -> a | None -> e_zero in
      let b = match v with Some b -> b | None -> get_last s.pre l in
      assigned_range s obj l a b

(* -------------------------------------------------------------------------- *)
(* --- Loc Comparison                                                     --- *)
(* -------------------------------------------------------------------------- *)

let loc_compare f_cmp i_cmp p q =
  match F.is_equal (a_base p) (a_base q) with
    | Logic.No -> p_false
    | Logic.Yes -> i_cmp (a_offset p) (a_offset q)
    | Logic.Maybe -> p_call f_cmp [p;q]

let is_null l = p_equal l null
let loc_eq = p_equal
let loc_lt = loc_compare a_lt p_lt
let loc_leq = loc_compare a_leq p_leq
let loc_neq = p_neq
let loc_offset obj p q = 
  let delta = e_sub (a_offset q) (a_offset p) in
  e_fact (Ctypes.sizeof_object obj) delta

(* -------------------------------------------------------------------------- *)
(* --- Validity                                                           --- *)
(* -------------------------------------------------------------------------- *)

let s_valid sigma p n = p_call p_valid [Sigma.value sigma T_alloc;p;n]

let valid sigma = function
  | Rloc(obj,l) -> s_valid sigma l (e_int64 (size_of_object obj))
  | Rrange(l,obj,Some a,Some b) ->
      let l = shift l obj a in
      let n = e_fact (size_of_object obj) (e_range a b) in
      s_valid sigma l n
  | Rrange(l,obj,None,Some b) ->
      let n = e_add b e_one in
      s_valid sigma l (e_fact (size_of_object obj) n)
  | Rrange(l,obj,Some a,None) ->
      let k = e_add (a_offset l) (e_fact (size_of_object obj) a) in
      p_and (p_lt e_zero k) (p_leq k (get_alloc sigma l))
  | Rrange(l,_obj,None,None) ->
      p_lt e_zero (get_alloc sigma l)

type alloc = ALLOC | FREE

let allocates spost xs a =
  if xs = [] then spost, [] else
    let spre = Sigma.havoc_chunk spost T_alloc in
    let alloc =
      List.fold_left
	(fun m x -> 
	   let size = match a with
	     | FREE -> Int64.zero 
	     | ALLOC -> size_of_typ x.vtype 
	   in F.e_set m (BASE.get x) (e_int64 size))
	(Sigma.value spre T_alloc) xs in
    spre , [ p_equal (Sigma.value spost T_alloc) alloc ]

let framed sigma = 
  let frame phi chunk =
    if Sigma.mem sigma chunk 
    then [ p_call phi [Sigma.value sigma chunk] ]
    else [] 
  in 
  frame p_linked T_alloc @ frame p_framed M_pointer

let scope sigma scope xs = match scope with
  | Mcfg.SC_Global -> sigma , framed sigma
  | Mcfg.SC_Function_in -> sigma , []
  | Mcfg.SC_Function_frame | Mcfg.SC_Block_in -> allocates sigma xs ALLOC
  | Mcfg.SC_Function_out | Mcfg.SC_Block_out -> allocates sigma xs FREE

(* -------------------------------------------------------------------------- *)
(* --- Domain                                                             --- *)
(* -------------------------------------------------------------------------- *)

type range = 
  | LOC of term * term (* loc - size *)
  | RANGE of term * Vset.set (* base - range offset *)

let range = function
  | Rloc(obj,l) -> 
      LOC( l , e_int64 (size_of_object obj) )
  | Rrange(l,obj,Some a,Some b) ->
      let l = shift l obj a in
      let n = e_fact (size_of_object obj) (e_range a b) in
      LOC( l , n )
  | Rrange(l,_obj,None,None) ->
      RANGE( a_base l , Vset.range None None )
  | Rrange(l,obj,Some a,None) ->
      let se = size_of_object obj in
      RANGE( a_base l , Vset.range (Some (e_fact se a)) None )
  | Rrange(l,obj,None,Some b) ->
      let se = size_of_object obj in
      RANGE( a_base l , Vset.range None (Some (e_fact se b)) )

let range_set = function
  | LOC(l,n) -> 
      let a = a_offset l in
      let b = e_add a n in
      a_base l , Vset.range (Some a) (Some b)
  | RANGE(base,set) -> base , set

let r_included r1 r2 =
  match r1 , r2 with
    | LOC(l1,n1) , LOC(l2,n2) -> 
	p_call p_included [l1;n1;l2;n2]
    | _ -> 
	let base1,set1 = range_set r1 in
	let base2,set2 = range_set r2 in
	p_and (p_equal base1 base2) (Vset.subset set1 set2)

let r_disjoint r1 r2 =
  match r1 , r2 with
    | LOC(l1,n1) , LOC(l2,n2) -> 
	p_call p_separated [l1;n1;l2;n2]
    | _ -> 
	let base1,set1 = range_set r1 in
	let base2,set2 = range_set r2 in
	p_imply (p_equal base1 base2) (Vset.disjoint set1 set2)

let included s1 s2  = r_included (range s1) (range s2)
let separated s1 s2 = r_disjoint (range s1) (range s2)

(* -------------------------------------------------------------------------- *)
