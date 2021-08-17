(*****************************************************************************)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Étienne Marais <etienne.marais@nomadic-labs.com>       *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

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
  (** {1 Gets arguments} *)

  (** [want_time ()] returns true if the time metric is wanted. *)
  val want_time : unit -> bool

  (** [want_power ()] returns Some (energy type) if the power metric
      is wanted. Else, it returns None. *)
  val want_power : unit -> string option

  (** [want_signal ()] returns true if a signal handler is requested. *)
  val want_signal : unit -> bool

  (** [want_path ()] returns the path value. Default is /tmp/oxymeter-report. *)
  val want_path : unit -> string

  (** [want_lwt ()] returns true if you need a Lwt context. *)
  val want_lwt : unit -> bool

  (** {1 Specifications} *)

  (** Specification for a potential power argument in command line. *)
  val power_spec : string * Arg.spec * string

  (** Specification for a potential time argument in command line. *)
  val time_spec : string * Arg.spec * string

  (** Specification for a potential signal argument in command line. *)
  val signal_spec : string * Arg.spec * string

  (** Specification for a potential path argument in command line. *)
  val path_spec : string * Arg.spec * string

  (** Specification for a potential lwt-context argument in command line. *)
  val lwt_spec : string * Arg.spec * string
end
