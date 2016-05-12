module Main exposing (main)

import Json exposing(..)
import Json.Encode
import DateFormat
import String
import Types exposing (..)
import MockData
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.App as Html
import WebSocket


type alias Model =
    { processes : List Process, json : String }


type Msg
    = NewMessage String


main : Program Never
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


readFirstStatus : Cmd a
readFirstStatus =
    let
        url =
            "ws://127.0.0.1:9000/stream"

        obj =
            Json.Encode.object [ ( "type", Json.Encode.string "readStatus" ) ]

        msg =
            Json.Encode.encode 0 obj
    in
        WebSocket.send url msg


init : ( Model, Cmd Msg )
init =
    ( Model MockData.data "Waiting for status ..."
    , readFirstStatus
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen "ws://127.0.0.1:9000/stream" NewMessage


toRecord process =
    { pid = process.pid
    , name = process.name
    , host = process.host
    , start = process.start |> DateFormat.format "%d/%m/%Y"
    , memory = Basics.toString process.memory
    , cpu = Basics.toString process.cpu
    , status = process.status |> Basics.toString |> String.toLower
    , class = "process " ++ process.name
    }


toSpan : String -> String -> Html a
toSpan cls txt =
    span [ class cls ] [ text txt ]


display record =
    li [ class record.class ]
        [ div [ class "content" ]
            [ (toSpan "pid" record.pid)
            , (toSpan "name" record.name)
            , (toSpan "host" record.host)
            , (toSpan "start" record.start)
            , (toSpan "mem" record.memory)
            , (toSpan "cpu" record.cpu)
            , (toSpan ("status " ++ record.status) record.status)
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
            , status = "Status"
            , class = "titles"
            }

        items =
            (([ titles ] ++ procs) |> List.map display)
    in
        div []
            [ div [ class "main-content" ]
                [ h3 [ class "title" ] [ text "Processes" ]
                , ul [ class "process-list" ] items
                ]
            , pre [] [ code [] [ text model.json ] ]
            ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewMessage str ->
            ( { model | json = str }, Cmd.none )
