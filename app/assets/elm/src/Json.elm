module Json exposing (decode)

import Maybe
import Date
import Json.Decode exposing (..)
import Types exposing (..)


decode : String -> Maybe Process
decode json =
    case decodeString ("status" := string) json of
        Ok status ->
            case status of
                "running" ->
                    decodeRunning json

                "down" ->
                    decodeDown json

                _ ->
                    Nothing

        Err error ->
            Nothing


decodeRunning : String -> Maybe Process
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
    in
        case decodeString decoder json of
            Ok ( name, host, cpu, memory, pid, startDate, currentDate ) ->
                let
                    proc =
                        { name = name
                        , host = host
                        , status = Running
                        , cpu = Just cpu
                        , memory = Just memory
                        , pid = Just pid
                        , started = Just (Date.fromTime startDate)
                        , current = Just (Date.fromTime currentDate)
                        }
                in
                    Just proc

            Err error ->
                Nothing


decodeDown : String -> Maybe Process
decodeDown json =
    let
        decoder =
            object3 (,,)
                ("name" := string)
                ("host" := string)
                ("reason" := string)
    in
        case decodeString decoder json of
            Ok ( name, host, reason ) ->
                let
                    proc =
                        Process name host (Down reason) Nothing Nothing Nothing Nothing Nothing
                in
                    Just proc

            Err error ->
                Nothing
