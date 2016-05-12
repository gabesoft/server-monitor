module Types exposing (..)

import Date


type Status
    = Up
    | Down


type ProcessResultData
    = Success Process
    | Error String


type alias ProcessResult =
    { name : String, process : ProcessResultData }


type alias Process =
    { pid : String
    , name : String
    , host : String
    , start : Date.Date
    , memory : Float
    , cpu : Float
    , status : Status
    }
