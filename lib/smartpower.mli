type station

val create : string -> int -> station Lwt.t

val delete : station Lwt.t -> unit Lwt.t

val observe : station Lwt.t -> Report.t Lwt.t
