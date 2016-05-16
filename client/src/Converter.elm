module Converter exposing (decode)

import Maybe
import Date
import Result
import Json.Decode exposing (..)
import Types exposing (..)


decode : String -> Result String Process
decode json =
    let
        toProc : String -> Result String Process
        toProc status =
            case status of
                "running" ->
                    decodeRunning json

                "down" ->
                    decodeDown json

                _ ->
                    Err ("Invalid status " ++ status)

        status =
            decodeString ("status" := string) json
    in
        Result.andThen status toProc


decodeRunning : String -> Result String Process
decodeRunning json =
    let
        decoder =
            object7 (,,,,,,)
                ("name" := string)
                ("host" := string)
                ("cpu" := float)
                ("memory" := float)
                ("pid" := string)
                ("startDate" := float)
                ("currentDate" := float)

        toProc ( name, host, cpu, memory, pid, startDate, currentDate ) =
            let
                proc =
                    (makeProcess name host Running)
            in
                { proc
                    | cpu = Just cpu
                    , memory = Just memory
                    , pid = Just pid
                    , started = Just (Date.fromTime startDate)
                    , current = Just (Date.fromTime currentDate)
                }
    in
        decodeString decoder json
            |> Result.map toProc


makeProcess : String -> String -> Status -> Process
makeProcess name host status =
    Process name host status Nothing Nothing Nothing Nothing Nothing


decodeDown : String -> Result String Process
decodeDown json =
    let
        decoder =
            object3 (,,)
                ("name" := string)
                ("host" := string)
                ("reason" := string)

        toProc ( name, host, reason ) =
            makeProcess name host (Down reason)
    in
        decodeString decoder json
            |> Result.map toProc
