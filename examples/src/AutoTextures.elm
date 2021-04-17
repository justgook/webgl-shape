module AutoTextures exposing (main)

import AutoTextures.Asset as Asset
import Browser
import Browser.Dom as Dom
import Math.Vector2 exposing (vec2)
import Math.Vector3 exposing (Vec3)
import Task
import WebGL.Game2d as Game2d exposing (Screen, TextureManager, move, rgb, textureManager)
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
                Game2d.resize |> Sub.map (\screen model -> { model | screen = screen })
        }


type alias Model =
    Game2d.Model Screen {}


init _ =
    let
        cmd =
            Dom.getViewport
                |> Task.map
                    (\{ scene } model -> { model | screen = Game2d.toScreen scene.width scene.height })
                |> Task.attempt (Result.withDefault identity)
    in
    { textures = textureManager
    , entities = []
    , screen = Game2d.toScreen 300 300
    }
        |> Game2d.update view identity
        |> Tuple.mapSecond (\a -> Cmd.batch [ a, cmd ])


view : a -> List (TexturedShape String)
view _ =
    [ [ rectangle (rgb 239 41 41) 20 20 |> move 0 10
      , rectangle (rgb 114 159 207) 20 20 |> move 0 -10
      , tile 20 27 Asset.spritesheet 0
      , tilemap 16 16 Asset.tilemap Asset.lut
      ]
        |> group
    ]



{- SHAPES -}


rectangle : Vec3 -> Float -> Float -> TexturedShape key
rectangle color w h =
    Render.rect color
        |> AutoTextures.shape w h


tile : Float -> Float -> key -> Int -> TexturedShape key
tile tileW tileH tileset index =
    tileset
        |> AutoTextures.textured
            (\t ->
                Render.tile t (vec2 tileW tileH) (Util.size t) (toFloat index)
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
