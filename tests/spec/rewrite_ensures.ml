(* dynamic plug-in to test rewriting of formals in ensures clauses *)

let rewrite _ =
  Ast.compute ();
  Globals.Functions.iter
    (fun kf -> kf.Db_types.spec <- Logic_interp.formals_in_ensures kf)

include
    Plugin.Register (struct
                       let name = "rewrite-ensures"
                       let shortname = name
                       let descr = "test purposes only"
                       let module_name = "Rewrite_ensures"
                       let is_dynamic = true
                     end)
;;

Db.Main.extend rewrite;;