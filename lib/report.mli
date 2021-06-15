type t

val create :
  ?joule:float ->
  ?volt:float ->
  ?ampere:float ->
  ?power:float ->
  ?watt_hour:float ->
  float ->
  t

val encode : t Data_encoding.t

val json_of_t : t -> Data_encoding.json
