module AutoTextures exposing (main)

import Browser
import Html exposing (Html)
import Math.Vector3 exposing (Vec3)
import WebGL.Game2d as Game2d exposing (move, rgb)
import WebGL.Game2d.Render as Render exposing (Render)
import WebGL.Game2d.TexturedShape as AutoTextures exposing (Form(..), TexturedShape, group)


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


init : () -> ( (), Cmd msg )
init _ =
    ( (), Cmd.none )


update _ model =
    ( model, Cmd.none )


view : model -> Html msg
view _ =
    let
        textures _ =
            Nothing
    in
    [ [ rectangle (rgb 239 41 41) 20 20 |> move 0 10
      , rectangle (rgb 114 159 207) 20 20 |> move 0 -10
      ]
        |> group
    ]
        |> AutoTextures.toEntities 100 100 textures (::) []
        |> Tuple.first
        |> Game2d.view 100 100


rectangle : Vec3 -> Float -> Float -> TexturedShape key
rectangle color w h =
    Render.rect color |> AutoTextures.shape w h
