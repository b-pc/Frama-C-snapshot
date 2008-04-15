(**************************************************************************)
(*                                                                        *)
(*  This file is part of Frama-C.                                         *)
(*                                                                        *)
(*  Copyright (C) 2007-2008                                               *)
(*    CEA (Commissariat � l'�nergie Atomique)                             *)
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

(* $Id: project.mli,v 1.28 2008/12/12 12:46:33 uid581 Exp $ *)

(** Projects management.

    A project groups together all the internal states of Frama-C. An internal
    state is roughly the result of a computation which depends of an AST. It is
    possible to have many projects at the same time. For registering a new
    state in the Frama-C projects, apply the functor {!Computation.Register}.

    @plugin development guide *)

val set_debug_level: int -> unit
  (** Set the level of debug: 0 = no level; 1 = small debugging messages and so
      on. *)

(* ************************************************************************* *)
(** {2 Datatypes} *)
(* ************************************************************************* *)

type t
  (** Type of a project.
      @plugin development guide *)

type project = t
    (** Alias for the project type. *)

val repr: t Type.t
  (** Identifier for type [t]. *)

val dummy: t
  (** A dummy project: should only be used to initialized reference but must
      never be put something inside. *)

(* ************************************************************************* *)
(** {2 Kinds dealing with Project}

    There are two kinds of kinds in Frama-C: datatypes and computations. They
    are merely used for theirs dependencies:
    - The datatypes dependencies are useful when loading: mainly we have to
    re-hashcons all the values in a "good" order.
    - The computations dependencies are useful for actions which use
    selection (e.g. project copying): for example, we have to be able to
    copying some states with all their dependencies. *)
(* ************************************************************************* *)

(** Common signature of kinds.
    @see <kind.html> kind. *)
module type KIND = sig

  type t
    (** Type of kinds. *)

  val dummy : t
    (** A dummy kind.
	@plugin development guide *)

  val name: t -> string
    (** Name of a kind. *)

  val add_dependency: t -> t -> unit
    (** [add_dependency k1 k2] indicates that the state kind [k1] depends on
	the state kind [k2], that is an action of the state kind [k2] must be
	done before one of the state kind [k1]. Actions are cleaning, copying,
	loading and saving.
	@plugin development guide *)

end

val identity: 'a -> 'a
  (** The identity function. *)

val is_identity: ('a -> 'a) -> bool
  (** @return true iff the given function is (physically) {!identity}. *)

(** Datatype implementation and how to register them. *)
module Datatype : sig

  module type INPUT = sig

    type t
      (** The datatype to register. *)

    val rehash: t -> t
      (** How to rehashcons the datatype. *)

    val copy: t -> t
      (** How to deeply copy the datatype.
	  The following invariant must hold: forall (p:t), copy s != s. *)

    val name: string
      (** Name of the datatype.
	  Have to be different of others registered datatypes. *)

  end

  (** Output of {!Datatype.Register}. *)
  module type S = sig

    include INPUT
      (** Exportation of inputs (easier use of [Datatype.Register]). *)

    val register_comparable:
      ?compare:(t -> t -> int) ->
      ?equal:(t -> t -> bool) ->
      ?hash:(t -> int) ->
      ?physical_hash:(t -> int) ->
      unit -> unit
      (** Allow to register a specific [compare], [equal], [hash] and
	  [physical_hash] functions for the datatype.

	  [hash] and [equal] have to be compatible, that is:
	  forall x y, equal x y ==> hash x = hash y.

	  [physical_hash] has to be compatible with physical equality (==),
	  that is:
	  forall x y, x == y ==> physical_hash x = physical_hash y.

	  - default value for [compare] is [Pervasives.compare];
	  - default value for [equal] is [fun x y -> compare x y = 0] if
	  [compare] is provided; (=) otherwise.
	  - default value for [hash] is Hashtbl.hash;
	  - default value for [physical_hash] is [hash] if it is provided;
	  [Hashtbl.hash] otherwise.

	  Never call [registered_comparable] is equivalent to call
	  [register_comparable ()].

	  Note that, as usual in ocaml, the default values for [equal] and
	  [hash] are not compatible for all datastructures (though for the most
	  ones). *)

    val is_comparable_set: unit -> bool
      (** @return false if [register_comparable] has never been called. *)

    (** {3 Access to the functions registered by [registered_comparable]} *)

    val hash: t -> int
    val physical_hash: t -> int
    val equal: t -> t -> bool
    val compare: t -> t -> int

  end

  (** Register a new kind of datatype by side-effects.
      @plugin development guide *)
  module Register(Datatype:INPUT) : S with type t = Datatype.t

  (** Register a single datatype, not affected by hashconsing.
      @plugin development guide *)
  module Imperative(X:sig type t val copy: t -> t val name: string end) :
    S with type t = X.t

  (** Register a single datatype, not affected by hashconsing and copying.
      @plugin development guide *)
  module Persistent(X:sig type t val name: string end) :
    S with type t = X.t

  (** {3 Create a name from predefined ones}

      See module {!Namespace}. *)

  val extend_name: string -> string -> string
  val extend_name2: string -> string -> string -> string
  val extend_name3: string -> string -> string -> string -> string

end

(** Internal state (aka Computation) representation and how to register them.
    An internal state contains the result of a computation. *)
module Computation : sig

  include KIND
    (** Common operations. *)

  type selection
    (** Just an alias for [Project.Selection.t]. *)

  (** Main input signature of {!Computation.Register}. *)
  module type INPUT = sig

    type t
      (** Type of the state to register. *)

    val create: unit -> t
      (** How to create a new fresh state which must be equal to the initial
	  state: that is, if you never change the state, [create ()] and [get
	  ()] must be equal (see invariant 1 below). *)

    val clear: t -> unit
      (** How to clear a state. After cleaning, the state should be
	  observationaly the same that after its creation (see invariant 2
	  below).
	  @plugin development guide *)

    val get: unit -> t
      (** How to access to the current state. Be aware of invariants 3 and 4
	  below. *)

    val set: t -> unit
      (** How to change the current state. Be aware of invariants 3 and 4
	  below. *)

  (** The four following invariants must hold.
      {ol
      {- [create ()] returns a fresh value}
      {- forall [(p:t)] [copy p] returns a fresh value}
      {- forall [(p:t)], [create () = (clear p; set p; get ())]}
      {- forall [(p1:t),(p2:t)] such that [p1 != p2], [(set p1; get ()) != s2]}
      } *)
  end

  (** Some additional informations used by {!Computation.Register}. *)
  module type INFO = sig
    val name: string (** Name of the internal state. *)
    val dependencies : t list (** Dependencies of this internal state. *)
  end

  (** Output signature of {!Computation.Register}. *)
  module type OUTPUT = sig

    val self: t
      (** The kind of the registered state.
	  @plugin development guide *)

    val select: Kind.how -> selection -> selection
      (** [select sel] add the registered state to the given selection in a
	  functional way. *)

    val depend: t -> unit
      (** [depend k] adds a dependencies from [k] to [me]. *)

    val mark_as_computed: ?project:project -> unit -> unit
      (** Indicate that the registered state will not change again for the
	  given project (default is [current ()]). *)

    val is_computed: ?project:project -> unit -> bool
      (** Returns [true] iff the registered state will not change again for the
	  given project (default is [current ()]). *)

    val do_not_save: unit -> unit
      (** Call this function if the registered state must not be save/load
	  on/from disk. When loading, a new state (generated using [create]) is
	  used instead. *)

    (** Exportation of some inputs (easier use of [Computation.Register]). *)

    module Datatype: Datatype.S
    val name: string

  end

  (** [Register(Datatype)(State)(Info)] registers a new kind of computation by
      side-effect.
      [Datatype] represents the datatype of a state, [State] explains how to
      deal with a state and [Info] mainly details the dependencies of the
      computation (i.e. what computations should be done before this one).
      @plugin development guide *)
  module Register
    (Datatype: Datatype.S)
    (State: INPUT with type t = Datatype.t)
    (Info: INFO)
    : OUTPUT with module Datatype = Datatype

  val dump_dependencies:
    ?only:selection -> ?except:selection -> string -> unit
    (** Debugging purpose only. *)

end

(** Selection of kinds of computation.
    @plugin development guide *)
module Selection : Kind.SELECTION with type kind = Computation.t
				  and type t = Computation.selection

(* ************************************************************************* *)
(** {2 Operations on all projects} *)
(* ************************************************************************* *)

val create: string -> t
  (** Create a new project with the given name and attach it after the existing
      projects (so the current project, if existing, is unchanged).
      The given name may be already used by another project.
      @plugin development guide *)

val register_create_hook: (t -> unit) -> unit
  (** [register_create_hook f] adds a hook on function [create]: each time a
      new project [p] is created, [f p] is applied.

      The order in which hooks are applied is the same than the order in which
      hooks are registered. *)

exception NoProject
  (** May be raised by [current]. *)

val current: unit -> t
  (** The current project.
      @raise NoProject if there is no project.
      @plugin development guide *)

val is_current: t -> bool
  (** Check whether the given project is the current one or not. *)

val iter_on_projects: (t -> unit) -> unit
  (** iteration on project starting with the current one. *)

val find_all: string -> t list
  (** Find all projects with the given name. *)

val clear_all: unit -> unit
  (** Clear all the projects: all the internal states of all the projects are
      now empty (wrt the action registered with {!register_todo_on_clear}). *)

(** {3 Inputs/Outputs} *)

exception IOError of string
  (** @plugin development guide *)

val save_all: string -> unit
  (** Save all the projects in a file.
      @raise IOError a project cannot be saved.
  *)

val load_all: string -> unit
  (** Load all the projects from a file.
      For each project to load, the specification is the same than
      {!Project.load}.
      @raise IOError if a project cannot be loaded.
      @plugin development guide *)

val register_before_load_hook: (unit -> unit) -> unit
  (** [register_before_load_hook f] adds a hook called just before loading
      **each project** (more precisely, the project exists but is empty while
      the hook is applied): if [n] projects are on disk, the same hook will be
      called [n] times (one call by project).

      Besides, for each project, the order in which the hooks are applied is
      the same than the order in which hooks are registered. *)

val register_after_load_hook: (unit -> unit) -> unit
  (** [register_before_load_hook f] adds a hook called just after loading
      **each project**: if [n] projects are on disk, the same hook will be
      called [n] times (one call by project).

      Besides, for each project, the order in which the hooks are applied is
      the same than the order in which hooks are registered. *)

(* ************************************************************************* *)
(** {2 Operations on one project}

    Most operations have two optional arguments, called [only] and [except] of
    type [selection].
    - If [only] is specified, only the selected state kinds are copied.
    - If [except] is specified, those selected state kinds are not copied (even
    if they are also selected by [only]).
    Use it carefuly because Frama-C may become lost and inconsistent if these
    specifications are incorrects. *)
(* ************************************************************************* *)

val name: t -> string
  (** Project name. Two projects may have the same name. *)

val unique_name: t -> string
  (** Return a project name based on {!name} but different of each others
      [unique_name]. *)

val from_unique_name: string -> t
  (** Return a project based on {!unique_name}.
      @raise Not_found if no project has this unique name.
  *)

val set_current: ?only:Selection.t -> ?except:Selection.t -> t -> unit
  (** Set the current project with the given one.
      @raise Invalid_argument if the given project does not exist anymore.
      @plugin development guide *)

val register_after_set_current_hook: user_only:bool -> (unit -> unit) -> unit
  (** [register_after_set_current_hook f] adds a hook on function
      {!set_current}.
      - If [user_only] is [true], then each time {!set_current} is directly
      called by an user of this library, [f ()] is applied.
      - If [user_only] is [false], then each time {!set_current} is applied
      (even indirectly through {!Project.on}), [f ()] is applied.
      The order in which each hook is applied is unspecified. *)

val on:
  ?only:Selection.t -> ?except:Selection.t -> t -> ('a -> 'b) -> 'a -> 'b
  (** [on p f x] sets the current project to [p], computes [f x] then
      restores the current project. You should use this function if you use a
      project different of [current ()].
      @plugin development guide *)

val copy:
  ?only:Selection.t -> ?except:Selection.t -> ?src:t -> t -> unit
  (** Copy a project into another one. Default project for [src] is [current
      ()]. Replace the destination by [src].
      @plugin development guide *)

val clear:
  ?only:Selection.t -> ?except:Selection.t -> ?project:t -> unit -> unit
  (** Clear the given project. Default project is [current ()]. All the
      internal states of the given project are now empty (wrt the action
      registered with {!register_todo_on_clear}). *)

val register_todo_on_clear: (unit -> unit) -> unit
  (** Register action to perform just before clearing a project. *)

val remove: ?project:t -> unit -> unit
  (** Default project is [current ()]. If the current project is removed, then
      the new current project is the previous current project if it still
      exists (and so on). *)

(** {3 Projects are comparable values} *)

val compare: t -> t -> int
val equal: t -> t -> bool
val hash: t -> int

(** {3 Inputs/Outputs} *)

val save:
  ?only:Selection.t -> ?except:Selection.t -> ?project:t -> string -> unit
  (** Save a given project in a file. Default project is [current ()].
      @raise IOError if the project cannot be saved.
      @plugin development guide *)

val load:
  ?only:Selection.t -> ?except:Selection.t -> name:string -> string -> t
  (** Load a file into a new project given by its name.
      More precisely, [load only except name file]:
      {ol
      {- creates a new project;}
      {- performs all the registered [before_load] actions, following the
      datatype dependencies;}
      {- loads the (specified) states of the project and rehashcons them
      (following the computation dependencies); and}
      {- performs all the registered [after_load] actions.}
      }
      @raise IOError if the project cannot be loaded
      @return the new project containing the loaded data.
      @plugin development guide *)

(*
  Local Variables:
  compile-command: "LC_ALL=C make -C ../.. -j"
  End:
*)