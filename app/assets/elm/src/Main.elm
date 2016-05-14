module Main exposing (main)

import Interop exposing (readStatus)
import Html.Events exposing (onClick)
import Maybe exposing (withDefault)
import Json exposing (decode)
import DateFormat
import Types exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.App as Html
import WebSocket
import Platform.Sub exposing (batch)


type alias Model =
    { processes : List Process, url : String }


type alias Flags =
    { socketUrl : String }


type Msg
    = NewMessage String
    | ReadStatus String


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
    in
        ( { processes = [], url = url }, sendReadStatus url )


subscriptions : Model -> Sub Msg
subscriptions model =
    batch
        [ WebSocket.listen model.url NewMessage
        , readStatus ReadStatus
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewMessage str ->
            case decode str of
                Just proc ->
                    ( { model | processes = replace model.processes proc }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        ReadStatus _ ->
            ( model, sendReadStatus model.url )


sendReadStatus : String -> Cmd Msg
sendReadStatus url =
    WebSocket.send url """{ "type": "readStatus" }"""


toRecord process =
    { pid = process.pid |> withDefault ""
    , name = process.name
    , host = process.host
    , start =
        case process.started of
            Just date ->
                date |> DateFormat.format "%d/%m/%Y"

            Nothing ->
                ""
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
            List.map toRecord model.processes

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
                    , onClick (ReadStatus model.url)
                    ]
                    [ text "Refresh" ]
                ]
            ]


replace : List Process -> Process -> List Process
replace list proc =
    let
        has =
            list |> List.filter (\p -> p.name == proc.name) |> List.length |> \x -> x > 0
    in
        case has of
            True ->
                List.map
                    (\p ->
                        if p.name == proc.name then
                            proc
                        else
                            p
                    )
                    list

            False ->
                list ++ [ proc ]
