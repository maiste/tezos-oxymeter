module Info : sig
  type t

  type category = private Energy | Time

  val create : date:string -> time:string -> category -> Ezjsonm.t -> t

  val date : t -> string

  val time : t -> string

  val category : t -> category

  val json : t -> Ezjsonm.t
end

module Data : sig
  type t

  val empty : t

  val energy : t -> Info.t list

  val time : t -> Info.t list
end

val extract_data_from_r : string -> (Data.t, string) result
