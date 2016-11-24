module Components.WorkspaceSelector exposing (Model, Msg, init, update, view, getValue)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on)
import Json.Decode as Json

import Asana.Model as Asana

type Msg =
    Selected (Maybe Asana.WorkspaceId)

type alias Model =
    { workspaces : List Asana.WorkspaceResource
    , selected : Maybe Asana.WorkspaceId
    }

init : List Asana.WorkspaceResource -> (Model, Cmd Msg)
init workspaces =
    ({ workspaces = workspaces, selected = Nothing }, Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Selected (mSelected) ->
            ({ model | selected = mSelected }, Cmd.none)

view : Model -> Html Msg
view { workspaces, selected } =
    let
        attrs =
            [ class "WorkspaceSelector"
            , on "change" onChange
            ]
        options =
            option [value ""] [] :: List.map workspaceOption workspaces
    in
        select attrs options

getValue : Model -> Maybe Asana.WorkspaceId
getValue = .selected

--------------------------------------------------------------------------------
-- Private

onChange : Json.Decoder Msg
onChange =
    let
        strToMaybe str =
            Debug.log "Decoding: " <|
            if str == ""
                then Nothing
                else Just str
    in
        Json.map Selected <| Json.map strToMaybe <| Json.at ["target", "value"] Json.string

workspaceOption : Asana.WorkspaceResource -> Html Msg
workspaceOption {id, name} =
    option [ value id ] [ text name ]