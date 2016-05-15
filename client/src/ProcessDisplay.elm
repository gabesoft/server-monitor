module ProcessDisplay exposing (..)

import Date
import DateFormat
import Maybe exposing (withDefault)
import Html exposing (span, div, text, li)
import Html.Attributes exposing (class, title)
import Types exposing (..)
import String exposing (padLeft)


toListItems processes =
    let
        procs =
            List.map format processes

        titles =
            { pid = "Pid"
            , name = "Name"
            , host = "Host"
            , start = "Start Date"
            , duration = "Uptime"
            , memory = "Memory"
            , cpu = "Cpu"
            , status = ( "Status", "" )
            , class = "titles"
            }

        items =
            (([ titles ] ++ procs) |> List.map toListItem)
    in
        items


toListItem record =
    let
        ( statusText, statusTitle ) =
            record.status
    in
        li [ class record.class ]
            [ div [ class "content" ]
                [ ( "pid", record.pid, "" ) |> toSpan
                , ( "name", record.name, "" ) |> toSpan
                , ( "host", record.host, "" ) |> toSpan
                , ( "start", record.start, "" ) |> toSpan
                , ( "duration", record.duration, "" ) |> toSpan
                , ( "mem", record.memory, "" ) |> toSpan
                , ( "cpu", record.cpu, "" ) |> toSpan
                , ( "status " ++ statusText, statusText, statusTitle ) |> toSpan
                ]
            ]


format process =
    { pid = process.pid |> withDefault "00000"
    , name = process.name
    , host = process.host
    , start =
        case process.started of
            Just date ->
                date |> DateFormat.format "%d/%m/%Y"

            Nothing ->
                "00/00/0000"
    , duration = uptime process.started process.current
    , memory = process.memory |> withDefault 0.0 |> Basics.toString
    , cpu = process.cpu |> withDefault 0.0 |> Basics.toString
    , status =
        case process.status of
            Running ->
                ( "up", "" )

            Down reason ->
                ( "down", reason )
    , class = "process " ++ process.name
    }


uptime : Maybe Date.Date -> Maybe Date.Date -> String
uptime from to =
    let
        x =
            from |> withDefault (Date.fromTime 0) |> Date.toTime

        y =
            to |> withDefault (Date.fromTime 0) |> Date.toTime

        hi =
            Basics.max x y |> round

        lo =
            Basics.min x y |> round

        d =
            3600 * 24

        h =
            3600

        m =
            60

        diff =
            (hi - lo) // 1000

        days =
            diff // d

        hours =
            (diff - days * d) // h

        minutes =
            (diff - days * d - hours * h) // m

        format t n =
            t |> toString |> padLeft n '0'
    in
        (format days 2) ++ "d:" ++ (format hours 2) ++ "h:" ++ (format minutes 2) ++ "m"


toSpan ( classStr, textStr, titleStr ) =
    span [ class classStr, title titleStr ] [ text textStr ]