(** Module that represents a measure unit. *)
module type MEASURE = sig
  (** Abstract type to represent a measure. *)
  type t

  (** The name of file where the measure are exported. *)
  val file : string

  (** Tells if a measure is wanted or not. *)
  val wanted : unit -> bool

  (** Initialize the instrument. *)
  val init : string option -> unit

  (** Gets a measure. *)
  val getMeasure : unit -> t Lwt.t

  (** [diff x y] computes the difference between x and y. *)
  val diff : t -> t -> t Lwt.t

  (** Returns the representation of the {!t} value as a
      string. *)
  val to_string_lwt : t -> string Lwt.t

  (** Returns the representation of the {!t} value as
      an {!Ezjsonm.value}. *)
  val to_ezjsonm_lwt : t -> Ezjsonm.value Lwt.t
end

(** Module that represents an instrument to take and save
    mesures. *)
module type METRICS = sig
  (** [insert file fun_name state] inserts a new entry into
      the database, referenced as file.fun_name. It's either
      the starting of a measure or the end. *)
  val insert : string -> string -> [< `Start | `Stop ] -> unit Lwt.t

  (** [exist file fun_name] checks if there is already a
      reference to file.fun_name in the database. *)
  val exist : string -> string -> bool

  (** [generate_report name] builds a JSON report to {path}/name from the values
      present in the database. It creates the path if it doesn't exist.contents
      The default path is in [/tmp/oxymeter-report/]. *)
  val generate_report : ?path:string -> string -> unit Lwt.t
end

(** Functor to create an instrument to get {!METRICS} from
    a {!MEASURE} unit. *)
module MakeMetrics : functor (M : MEASURE) -> METRICS

(** Module to gather metrics about time. *)
module TimeMetrics : METRICS

(** Module to gather metrics about consumption. *)
module EnergyMetrics : METRICS
