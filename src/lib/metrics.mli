(** Module that represents a measure unit. *)
module type MEASURE = sig
  (** Abstract type to represent a measure. *)
  type t

  (** Gets a measure. *)
  val getMeasure : unit -> t

  (** [diff x y] computes the difference between x and y. *)
  val diff : t -> t -> t

  (** Returns the representation of the {!t} value as a
      string. *)
  val to_string : t -> string

  (** Returns the representation of the {!t} value as
      an {!Ezjsonm.value}. *)
  val to_json : t -> Ezjsonm.value
end

(** Module that represents an instrument to take and save
    mesures. *)
module type METRICS = sig
  (** [insert file fun_name state] inserts a new entry into
      the database, referenced as file.fun_name. It's either
      the starting of a measure or the end. *)
  val insert : string -> string -> [< `Start | `Stop ] -> unit

  (** [exist file fun_name] checks if there is already a
      reference to file.fun_name in the database. *)
  val exist : string -> string -> bool

  (** [generate_report ()] builds a JSON report from the values
      present in the database. *)
  val generate_report : unit -> Ezjsonm.value
end

(** Functor to create an instrument to get {!METRICS} from
    a {!MEASURE} unit. *)
module MakeMetrics : functor (M : MEASURE) -> METRICS

(** Module to gather metrics about time. *)
module TimeMetrics : METRICS
