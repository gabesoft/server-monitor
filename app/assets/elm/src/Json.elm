module Json exposing (decode)

import Date
import Json.Decode exposing (..)
import Types exposing (..)


decode : String -> ProcessResult
decode json =
    let
        decoder =
            object2 (,) ("name" := string) ("status" := string)
    in
        case decodeString decoder json of
            Ok ( name, status ) ->
                { name = name, process = decodeStatus status }

            Err error ->
                { name = "invalid", process = Error error }


decodeStatus : String -> ProcessResultData
decodeStatus json =
    case decodeString ("error" := string) json of
        Ok msg ->
            Error msg

        Err _ ->
            decodeValidStatus json


decodeValidStatus : String -> ProcessResultData
decodeValidStatus json =
    let
        decoder =
            object4 (,,,)
                ("pid" := string)
                ("cpu" := float)
                ("mem" := float)
                ("stime" := float)
    in
        case decodeString decoder json of
            Ok ( pid, cpu, mem, stime ) ->
                Success
                    { pid = pid
                    , cpu = cpu
                    , memory = mem
                    , start = Date.fromTime stime
                    , host = ""
                    , name = ""
                    , status = Up
                    }

            Err err ->
                Error err
