(** Gets the path from the environment variable METRICS_CONFIG_PATH.
    If the variable is not set, it takes the default value
    [metrics_config.json]. *)
val metrics_config_path : string

module JSON : sig
  (** [parse_file file_path] opens the file and parses it as a JSON
        value. If there is an error during the process, it returns
        None. If it succeeds, it returns Some JSON. *)
  val parse_file : string -> Ezjsonm.value option

  (** [parse_metrics_config] is just a shortcut for
       [parse_file metrics_config_path]. *)
  val parse_metrics_config : unit -> Ezjsonm.value option

  (** [extract_from_array json] extracts the list from [json] where
      [json] is an [Ezjsonm.value.`A]. Otherwise, it returns the
      empty list. *)
  val extract_from_array : Ezjsonm.value -> Ezjsonm.value list

  (** [extract_from_obj json] extracts the associative list from
      [json] where [json] is an [Ezjsonm.value.`O]. Otherwise, it
      returns the empty list. *)
  val extract_from_obj : Ezjsonm.value -> (string * Ezjsonm.value) list

  (** [extract_string] converts a [Ezjsonm.value.`String] into an
      OCaml string. *)
  val extract_from_string : Ezjsonm.value -> string
end
