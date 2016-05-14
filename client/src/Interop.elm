port module Interop exposing (..)


port socketUrl : (String -> msg) -> Sub msg

port readStatus : (String -> msg) -> Sub msg
