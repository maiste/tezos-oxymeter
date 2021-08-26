module Infix = struct
  let ( >>= ) = Result.bind

  let ( let* ) = Result.bind
end
