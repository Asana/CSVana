module Asana.Api exposing (Token, ApiResult, me, users, projectTypeahead, project, customField, createTask)

import Http
import Json.Decode exposing (Decoder, (:=), list, oneOf)
import Json.Encode as Encode exposing (Value)
import Task

import Asana.Model as Asana
import Asana.Encoder as Encoder
import Asana.Decoder as Decoder

apiRoot : String
apiRoot = "https://app.asana.com/api/1.0"

type alias Token = String
type alias ApiResult a = (Result Http.Error a)
type alias Query = List (String, String)

apiGetRequest : String -> Query -> Decoder a -> Token -> Cmd (ApiResult a)
apiGetRequest path query decoder token =
  let
      url = Http.url (apiRoot ++ path) query
      headers = [("Authorization", "Bearer " ++ token)]
      request =
          { url = url
          , headers = headers
          , verb = "GET"
          , body = Http.empty
          }
      httpRequest =
          Http.send Http.defaultSettings request
          |> Http.fromJson ("data" := decoder)
  in
      Task.perform Err Ok httpRequest

apiPostRequest : String -> Query -> Value -> Decoder a -> Token -> Cmd (ApiResult a)
apiPostRequest path query body decoder token =
  let
      url = Http.url (apiRoot ++ path) query
      headers = [("Authorization", "Bearer " ++ token)]
      request =
          { url = url
          , headers = headers
          , verb = "POST"
          , body = Http.string <| Encode.encode 4 <| Encode.object [("data", body)]
          }
      httpRequest =
          Http.send Http.defaultSettings request
          |> Http.fromJson ("data" := decoder)
  in
      Task.perform Err Ok httpRequest


me : Token -> Cmd (ApiResult Asana.User)
me =
    apiGetRequest "/users/me" [] Decoder.userDecoder

users : Asana.WorkspaceId -> Token -> Cmd (ApiResult (List Asana.User))
users workspaceId =
    let
        path = "/workspaces/" ++ workspaceId ++ "/users"
        query = [("opt_fields", "email,name,photo.image_128x128")]
    in
        apiGetRequest path query (list Decoder.userDecoder)

type TypeaheadType
    = TypeaheadProject
    | TypeaheadUser
    | TypeaheadTag
    | TypeaheadTask

typeaheadTypeStr : TypeaheadType -> String
typeaheadTypeStr resourceType =
    case resourceType of
        TypeaheadProject ->
            "project"
        TypeaheadUser ->
            "user"
        TypeaheadTag ->
            "tag"
        TypeaheadTask ->
            "task"

getTypeaheadOptions : TypeaheadType -> Decoder a -> Asana.Id -> String -> Token -> Cmd (ApiResult (List a))
getTypeaheadOptions resourceType decoder (workspaceId) fragment  =
    let
        resourceTypeStr = typeaheadTypeStr resourceType
        path = "/workspaces/" ++ workspaceId ++ "/typeahead"
        query =
            [ ("type", resourceTypeStr)
            , ("query", fragment)
            ]
    in
       apiGetRequest path query (Json.Decode.list decoder)

projectTypeahead : Asana.WorkspaceId -> String -> Token -> Cmd (ApiResult (List Asana.ProjectResource))
projectTypeahead =
    getTypeaheadOptions TypeaheadProject Decoder.resourceDecoder

project : Asana.ProjectId -> Token -> Cmd (ApiResult Asana.Project)
project projectId =
    let
        path = "/projects/" ++ projectId
    in
        apiGetRequest path [] Decoder.projectDecoder

customField : Asana.CustomFieldId -> Token -> Cmd (ApiResult Asana.CustomFieldInfo)
customField customFieldId =
    let
        path = "/custom_fields/" ++ customFieldId
    in
        apiGetRequest path [] Decoder.customFieldInfoDecoder

createTask : Asana.NewTask -> Token -> Cmd (ApiResult Asana.Task)
createTask newTask =
    let
        path = "/tasks"
        query = []
        body = Encoder.encodeTask newTask
    in
       apiPostRequest path query body Decoder.taskDecoder



