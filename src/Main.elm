module Main exposing (main)

import Browser
import Html exposing (Html, button, div, h1, input, text)
import Html.Attributes exposing (checked, class, disabled, name, placeholder, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode
import List.Extra as List


type alias Flags =
    { todos : List Todo
    }


type alias Model =
    { nextId : Int
    , todos : List Todo
    , newTodo : Maybe String
    }


type alias Todo =
    { id : Int
    , title : String
    , completed : Bool
    }


decodeTodo : Decoder Todo
decodeTodo =
    Decode.succeed Todo
        |> Decode.required "id" Decode.int
        |> Decode.required "title" Decode.string
        |> Decode.required "completed" Decode.bool


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { nextId = 1
      , todos = flags.todos
      , newTodo = Nothing
      }
    , Cmd.none
    )


type Msg
    = InputTodo String
    | AddTodo
    | PostedNewTodo (Result Http.Error Todo)
    | ToggleTodo Int
    | ReceivedUpdatedTodo (Result Http.Error Todo)
    | RemoveTodo Int
    | ConfirmDeleteTodo Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputTodo text ->
            ( { model
                | newTodo =
                    case String.length text of
                        0 ->
                            Nothing

                        _ ->
                            Just text
              }
            , Cmd.none
            )

        AddTodo ->
            case model.newTodo of
                Nothing ->
                    ( model, Cmd.none )

                Just text ->
                    ( model
                    , submitTodo text
                    )

        PostedNewTodo (Result.Ok todo) ->
            ( { model | newTodo = Nothing, todos = model.todos ++ [ todo ] }
            , Cmd.none
            )

        PostedNewTodo (Result.Err err) ->
            ( model
            , Cmd.none
            )

        ToggleTodo id ->
            let
                todo : Maybe Todo
                todo =
                    List.find (\t -> t.id == id) model.todos
            in
            case todo of
                Nothing ->
                    ( model, Cmd.none )

                Just t ->
                    ( model
                    , updateTodo { t | completed = not t.completed }
                    )

        ReceivedUpdatedTodo (Result.Ok todo) ->
            ( { model
                | todos =
                    List.map
                        (\t ->
                            if t.id == todo.id then
                                todo

                            else
                                t
                        )
                        model.todos
              }
            , Cmd.none
            )

        ReceivedUpdatedTodo (Result.Err err) ->
            ( model, Cmd.none )

        RemoveTodo id ->
            ( model, deleteTodo id )

        ConfirmDeleteTodo id ->
            ( { model
                | todos =
                    List.filter
                        (\todo -> todo.id /= id)
                        model.todos
              }
            , Cmd.none
            )


view : Model -> Html Msg
view model =
    div [ class "flex flex-col w-[400px] m-auto gap-4 pt-16" ]
        [ h1 [ class "text-2xl text-center" ] [ text "Prisma + Nuxt + Elm + Tailwind = 🎉" ]
        , input
            [ class "text-lg p-1 shadow-md"
            , value
                (Maybe.withDefault "" model.newTodo)
            , placeholder "What needs to be done?"
            , onInput InputTodo
            ]
            []
        , button
            [ class "rounded-full p-2 bg-blue-500 hover:bg-blue-600 transition duration-50 text-white w-32 m-auto cursor-pointer"
            , disabled (model.newTodo == Nothing)
            , onClick AddTodo
            ]
            [ text "Add Todo" ]
        , div [ class "w-full flex flex-col gap-2" ]
            (List.map
                (\todo ->
                    div
                        [ class "flex space-between items-center gap-4"
                        ]
                        [ input
                            [ type_ "checkbox"
                            , class "w-6 h-6 accent-green-500 hover:checked:accent-green-600"
                            , checked todo.completed
                            , name (String.fromInt todo.id)
                            , onClick (ToggleTodo todo.id)
                            ]
                            []
                        , div
                            [ class
                                ("flex-grow"
                                    ++ (if todo.completed then
                                            " text-green-700 italic"

                                        else
                                            ""
                                       )
                                )
                            ]
                            [ text todo.title ]
                        , button [ class "bg-red-500 hover:bg-red-600 transition duration-50 text-white w-8 h-8 rounded-full", onClick (RemoveTodo todo.id) ] [ text "X" ]
                        ]
                )
                model.todos
            )
        ]


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


submitTodo : String -> Cmd Msg
submitTodo input =
    Http.post
        { url = "/api/todo"
        , body =
            Http.jsonBody
                (Encode.object
                    [ ( "title", Encode.string input )
                    , ( "completed", Encode.bool False )
                    ]
                )
        , expect = Http.expectJson PostedNewTodo decodeTodo
        }


updateTodo : Todo -> Cmd Msg
updateTodo todo =
    Http.request
        { url = "/api/todo/" ++ String.fromInt todo.id
        , method = "PUT"
        , headers = []
        , body =
            Http.jsonBody
                (Encode.object
                    [ ( "id", Encode.int todo.id )
                    , ( "title", Encode.string todo.title )
                    , ( "completed", Encode.bool todo.completed )
                    ]
                )
        , expect = Http.expectJson ReceivedUpdatedTodo decodeTodo
        , timeout = Nothing
        , tracker = Nothing
        }


deleteTodo : Int -> Cmd Msg
deleteTodo id =
    Http.request
        { url = "/api/todo/" ++ String.fromInt id
        , method = "DELETE"
        , headers = []
        , body = Http.emptyBody
        , expect =
            Http.expectWhatever
                (\result ->
                    case result of
                        Result.Ok _ ->
                            ConfirmDeleteTodo id

                        Result.Err err ->
                            ConfirmDeleteTodo -1
                )
        , timeout = Nothing
        , tracker = Nothing
        }
