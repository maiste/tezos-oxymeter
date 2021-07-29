(** Gets the path from the environment variable METRICS_CONFIG_PATH.
    If the variable is not set, it takes the default value
    [metrics_config.json]. *)
val metrics_config_path : string

(** Module to manipulate JSON file. *)
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

  (** [export_to ~path json] writes [json] into the file
    referenced by [path]. *)
  val export_to : path:string -> Ezjsonm.value -> unit
end

(** Module to execute sys calls. *)
module Sys : sig
  (** [create_opt ~mode path] creates a directory at [path] with the [mode]
    permissions if it doesn't already exist. *)
  val create_opt : ?mode:int -> string -> unit
end

(** Module to manage name creation. *)
module Name : sig
  (** [timestamp_name name] generates a new name by adding
      a timestamp at creation time to [name]. *)
  val timestamp_name : string -> string
end

(** Module to handle argument declaration. *)
module Args : sig
  (** [want_time ()] returns true if the time metric is wanted. *)
  val want_time : unit -> bool

  (** [want_power ()] returns Some (energy type) if the power metric
      is wanted. Else, it returns false. *)
  val want_power : unit -> string option

  (** Specification for a potential power argument in command line. *)
  val power_spec : string * Arg.spec * string

  (** Specification for a potential time argument in command line. *)
  val time_spec : string * Arg.spec * string
end
