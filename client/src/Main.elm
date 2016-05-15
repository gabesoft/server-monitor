module Main exposing (main)

import DateFormat
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json exposing (decode)
import Maybe exposing (withDefault)
import Platform.Sub exposing (batch)
import Process exposing (sleep)
import Task exposing (perform)
import Types exposing (..)
import WebSocket


type alias Model =
    { processes : List Process, url : String }


type alias Flags =
    { socketUrl : String, processes : List String }


type Msg
    = NewMessage String
    | ReadStatus


main : Program Flags
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        url =
            flags.socketUrl

        processes =
            flags.processes
                |> List.map decode
                |> List.filterMap identity

        read _ =
            ReadStatus

        delay =
            sleep 100
    in
        ( { processes = processes, url = url }, perform read read delay )


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen model.url NewMessage


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewMessage str ->
            case decode str of
                Just proc ->
                    ( { model | processes = replace model.processes proc }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        ReadStatus ->
            ( model, readStatus model.url )


readStatus : String -> Cmd Msg
readStatus url =
    WebSocket.send url """{ "type": "readStatus" }"""


formatForDisplay process =
    { pid = process.pid |> withDefault "00000"
    , name = process.name
    , host = process.host
    , start =
        case process.started of
            Just date ->
                date |> DateFormat.format "%d/%m/%Y"

            Nothing ->
                "00/00/0000"
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


toSpan : DisplayItem -> Html a
toSpan item =
    case item of
        Span cls txt ->
            span [ class cls ] [ text txt ]

        SpanEx cls txt t ->
            span [ class cls, title t ] [ text txt ]


type DisplayItem
    = Span String String
    | SpanEx String String String


display record =
    li [ class record.class ]
        [ div [ class "content" ]
            [ Span "pid" record.pid |> toSpan
            , Span "name" record.name |> toSpan
            , Span "host" record.host |> toSpan
            , Span "start" record.start |> toSpan
            , Span "mem" record.memory |> toSpan
            , Span "cpu" record.cpu |> toSpan
            , SpanEx ("status " ++ (fst record.status))
                (fst record.status)
                (snd record.status)
                |> toSpan
            ]
        ]


view : Model -> Html Msg
view model =
    let
        procs =
            List.map formatForDisplay model.processes

        titles =
            { pid = "Pid"
            , name = "Name"
            , host = "Host"
            , start = "Start Date"
            , memory = "Memory"
            , cpu = "Cpu"
            , status = ( "Status", "" )
            , class = "titles"
            }

        items =
            (([ titles ] ++ procs) |> List.map display)
    in
        div []
            [ div [ class "main-content" ]
                [ h3 [ class "title" ] [ text "Processes" ]
                , ul [ class "process-list" ] items
                , button
                    [ class "refresh"
                    , onClick ReadStatus
                    ]
                    [ text "Refresh" ]
                ]
            ]


replace : List Process -> Process -> List Process
replace list proc =
    let
        exists =
            list
                |> List.filter (\p -> p.name == proc.name)
                |> List.length
                |> \x -> x > 0

        replace p =
            if p.name == proc.name then
                proc
            else
                p
    in
        case exists of
            True ->
                List.map replace list

            False ->
                list ++ [ proc ]
