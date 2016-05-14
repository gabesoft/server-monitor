module Types exposing (..)

import Maybe
import Date


type Status
    = Running
    | Down String


type alias Process =
    { name : String
    , host : String
    , status : Status
    , pid : Maybe String
    , started : Maybe Date.Date
    , current : Maybe Date.Date
    , memory : Maybe Float
    , cpu : Maybe Float
    }
