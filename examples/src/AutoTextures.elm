module AutoTextures exposing (main)

import AutoTextures.Asset as Asset
import Browser
import Math.Vector2 exposing (Vec2, vec2)
import Math.Vector3 exposing (Vec3)
import WebGL.Game2d as Game2d exposing (Screen, TextureManager, move, rgb, scale, textureManager)
import WebGL.Game2d.Render as Render exposing (Render)
import WebGL.Game2d.TexturedShape as AutoTextures exposing (Form(..), TextureLoader(..), TexturedShape, group)
import WebGL.Game2d.Util as Util
import WebGL.Texture as Texture exposing (Texture)


main : Program () Model (Model -> Model)
main =
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


view : Model -> List (TexturedShape String)
view { screen } =
    let
        sentence =
            "The quick brown fox jumps over the lazy dog"
    in
    [ [ rectangle (rgb 239 41 41) 20 20 |> move 0 10
      , rectangle (rgb 114 159 207) 20 20 |> move 0 -10
      , tile 20 27 Asset.spritesheet 0
      , tilemap 16 16 Asset.tilemap Asset.lut
      , Util.msdfFont 2 Asset.wordsConfig2 (rgb 0 0 0) (sentence ++ " (Source Code Pro)")
            |> move screen.left (screen.top - 50)
      , Util.msdfFont 2 Asset.wordsConfig3 (rgb 114 159 207) (sentence ++ " (Open Sans)")
            |> move screen.left (screen.top - 100)
      , Util.tileFont Asset.wordsConfig (rgb 114 159 207) sentence
            |> move screen.left (screen.top - 150)
      ]
        |> group
    ]



{- SHAPES -}


rectangle : Vec3 -> Float -> Float -> TexturedShape key
rectangle color w h =
    Render.rect color
        |> AutoTextures.shape w h


image : Float -> Float -> key -> TexturedShape key
image width height =
    AutoTextures.textured
        (\t ->
            Render.image t (Util.size t)
                |> AutoTextures.shape width height
        )


tile : Float -> Float -> key -> Int -> TexturedShape key
tile tileW tileH tileset index =
    tileset
        |> AutoTextures.textured
            (\t ->
                Render.tile t (vec2 tileW tileH) (Util.size t) index
                    |> AutoTextures.shape tileW tileH
            )


tilemap : Float -> Float -> key -> key -> TexturedShape key
tilemap tileW tileH tileset lut =
    AutoTextures.textured2
        (\t1 t2 ->
            let
                ( w2, h2 ) =
                    Texture.size t2
                        |> Tuple.mapBoth (toFloat >> (*) tileW) (toFloat >> (*) tileH)
            in
            Render.tilemap tileW tileH t1 t2
                |> AutoTextures.shape w2 h2
        )
        tileset
        lut
