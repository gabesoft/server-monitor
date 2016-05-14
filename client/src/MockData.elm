module MockData exposing (data)

import Date
import Types exposing (..)


make pid name host start memory cpu status =
    { pid = pid
    , name = name
    , start = Date.fromTime start
    , host = host
    , memory = memory
    , cpu = cpu
    , status = status
    }


data : List Process
data =
    [ (make "5919" "dask" "localhost:8009" 1462491151045 0.2 0.4 Up)
    , (make "5493" "ayne" "localhost:8029" 1461891111041 0.2 0.4 Up)
    , (make "8766" "seryth" "localhost:4009" 1462894151028 0.8 0.4 Up)
    , (make "5919" "vplug" "localhost:8012" 1460891151044 0.2 0.1 Down)
    , (make "5919" "xandar" "localhost:8041" 1262891351048 1.3 4.4 Up)
    ]
