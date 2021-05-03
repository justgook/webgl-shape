# WebGL Shape2d


2D wrapper for WebGL entities (also core of [webgl-playground](https://package.elm-lang.org/packages/justgook/webgl-playground/latest/)).
Easy way to create 2d shapes: rectangles, circles, sprites and other shapes, group them and reuse textures.

To create application like `Playground.picture`

    picture : (Model -> List (TexturedShape String)) -> Program () Model (Model -> Model)
    picture view =
        Browser.element
            { init = init
            , view = Shape2d.view
            , update = Shape2d.update view
            , subscriptions =
                \_ ->
                    Sub.map (\screen model -> { model | screen = screen }) Shape2d.resize
            }

    type alias Model =
        Shape2d.Model Screen {}

    init : flags -> ( Model, Cmd (Model -> Model) )
    init _ =
        { textures = Shape2d.textureManager
        , entities = []
        , screen = Shape2d.toScreen 300 300
        }
            |> Shape2d.update view identity
            |> Tuple.mapSecond (\cmd -> Cmd.batch [ cmd, Shape2d.requestScreen ])