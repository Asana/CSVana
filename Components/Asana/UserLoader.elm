module Components.Asana.UserLoader exposing (Model, Msg, Props, component, getChild, updateChild)

import Http
import Html exposing (Html)

import Base exposing (initC, updateC, viewC, subscriptionsC, stateC, mapCmd)
import Components.Asana.Model as Asana
import Components.Asana.Api as Api exposing (Token)
import Components.Asana.ApiResource as ApiResource
import Components.Asana.CommonViews exposing (..)

-- TODO: remove?

type alias Props model msg =
    { token : Api.Token
    , childSpec : Asana.User -> Base.Spec model msg
    }

type Msg msg
    = ApiResourceMsg (ApiResource.Msg Asana.User msg)
    | Load Asana.UserId

type alias Model model msg =
    ApiResource.Component Asana.User model msg

type alias Component model msg =
    Base.Component (Model model msg) (Msg msg)

type alias Spec model msg =
    Base.Spec (Model model msg) (Msg msg)

component : Props model msg -> Base.Spec (Model model msg) (Msg msg)
component props =
    { init = init props
    , update = update props
    , view = view props
    , subscriptions = subscriptions props
    }

getChild : Model model msg -> Maybe (Base.Component model msg)
getChild =
    ApiResource.getChild

load : Asana.UserId -> Component model msg -> (Component model msg, Cmd (Msg msg))
load =
    updateC << Load

--------------------------------------------------------------------------------
-- Private

init : Props model msg -> (Model model msg, Cmd (Msg msg))
init { childSpec } =
    mapCmd ApiResourceMsg <| initC <| ApiResource.component
        { childSpec = childSpec
        , unloadedView = unloadedView
        , loadingView = loadingIndicator
        , errorView = errorView
        }

update : Props model msg -> Msg msg -> Model model msg -> (Model model msg, Cmd (Msg msg))
update {token} msg model =
    case msg of
        ApiResourceMsg msg ->
            mapCmd ApiResourceMsg <| updateC msg model
        Load projectId ->
            mapCmd ApiResourceMsg <| ApiResource.load (Api.project projectId token) model

view : Props model msg -> Model model msg -> Html (Msg msg)
view _ model =
    Html.App.map ApiResourceMsg <| viewC model

subscriptions : Props model msg -> Model model msg -> Sub (Msg msg)
subscriptions props model =
    Sub.map ApiResourceMsg <| subscriptionsC model

