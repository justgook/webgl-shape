# WebGL Game2d


2D wrapper for WebGL entities (also core of [webgl-playground](https://package.elm-lang.org/packages/justgook/webgl-playground/latest/)).
Easy way to create 2d shapes: rectangles, circles, sprites and other shapes, group them and reuse textures.

To create application like `Playground.picture`

    picture : (Model -> List (TexturedShape String)) -> Program () Model (Model -> Model)
    picture view =
        Browser.element
            { init = init
            , view = Game2d.view
            , update = Game2d.update view
            , subscriptions =
                \_ ->
                    Sub.map (\screen model -> { model | screen = screen }) Game2d.resize
            }

    type alias Model =
        Game2d.Model Screen {}

    init : flags -> ( Model, Cmd (Model -> Model) )
    init _ =
        { textures = Game2d.textureManager
        , entities = []
        , screen = Game2d.toScreen 300 300
        }
            |> Game2d.update view identity
            |> Tuple.mapSecond (\cmd -> Cmd.batch [ cmd, Game2d.requestScreen ])