module Main exposing (main)

import Converter exposing (decode)
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Maybe exposing (withDefault)
import Platform.Sub exposing (batch)
import Process exposing (sleep)
import ProcessDisplay exposing (toListItems)
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


view : Model -> Html Msg
view model =
    div []
        [ div [ class "main-content" ]
            [ h3 [ class "title" ] [ text "Processes" ]
            , ul [ class "process-list" ] (toListItems model.processes)
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
            list |> List.any (\p -> p.name == proc.name)

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
