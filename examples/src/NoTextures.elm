module NoTextures exposing (main)

import Browser
import Html exposing (Html)
import Math.Vector3 exposing (Vec3)
import WebGL.Game2d as Game2d exposing (move, rgb)
import WebGL.Game2d.Render as Render exposing (Render)
import WebGL.Game2d.SolidShape as NoTextures exposing (Form(..), SolidShape, group)


main =
    Browser.sandbox
        { init = ()
        , view = view
        , update = \_ a -> a
        }


view : model -> Html msg
view _ =
    [ [ rectangle (rgb 239 41 41) 20 20 |> move 0 10
      , rectangle (rgb 114 159 207) 20 20 |> move 0 -10
      ]
        |> group
    ]
        |> NoTextures.toEntities 100 100
        |> Game2d.view 100 100


rectangle : Vec3 -> Float -> Float -> SolidShape
rectangle color w h =
    Render.rect color |> NoTextures.shape w h
