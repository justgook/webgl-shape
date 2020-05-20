module Main exposing (main)

import Dict
import Html.Attributes exposing (height, width)
import Math.Vector2 exposing (Vec2, vec2)
import Math.Vector3 exposing (Vec3, vec3)
import Math.Vector4 exposing (Vec4)
import WebGL exposing (Mesh, Shader, alpha)
import WebGL.Settings.DepthTest as DepthTest
import WebGL.Shape2d exposing (..)


main =
    [ rectangle (vec3 1 0 0) 30 30 |> zIndex 2
    , rectangle (vec3 0 1 0) 30 30 |> move 5 5 |> zIndex 1
    , rectangle (vec3 0 0 1) 30 30 |> move 10 10 |> zIndex -2
    ]
        |> WebGL.Shape2d.toEntities Dict.empty { width = 100, height = 100 }
        |> Tuple.first
        |> WebGL.toHtmlWith
            [ alpha True, WebGL.depth 0 ]
            [ width 100, height 100 ]


rectangle : Vec3 -> Float -> Float -> Shape2d
rectangle color width height =
    Shape2d
        { x = 0
        , y = 0
        , z = 0
        , a = 0
        , sx = 1
        , sy = 1
        , o = 1
        , form = Form width height (rectRender color)
        }


rectRender : Vec3 -> Render
rectRender color uP uT z opacity =
    WebGL.entityWith [ DepthTest.greaterOrEqual { write = True, near = 1, far = -1 } ]
        vertNone
        fragFill
        mesh
        { color = setAlpha color opacity
        , uP = uP
        , uT = uT
        , z = z
        }


{-| -}
vertNone : Shader { a | aP : Vec2 } { b | uP : Vec2, uT : Vec4, z : Float } {}
vertNone =
    -- 1 / (2 ^ 23 - 1)  = 0.000000119209304
    [glsl|
        precision mediump float;
        attribute vec2 aP;
        uniform vec4 uT;
        uniform vec2 uP;
        uniform float z;
        void main () {
            gl_Position = vec4(aP * mat2(uT) + uP, z * 1.19209304e-7, 1.0);
        }
    |]


fragFill : Shader a { b | color : Vec4 } {}
fragFill =
    [glsl|
        precision mediump float;
        uniform vec4 color;

        void main () {
            gl_FragColor = color;

        }
    |]


mesh : Mesh { aP : Vec2 }
mesh =
    WebGL.triangleStrip
        [ { aP = vec2 -1 -1 }
        , { aP = vec2 -1 1 }
        , { aP = vec2 1 -1 }
        , { aP = vec2 1 1 }
        ]


move : Float -> Float -> Shape2d -> Shape2d
move dx dy (Shape2d ({ x, y, a, sx, sy, o, form } as shape)) =
    Shape2d { shape | x = x + dx, y = y + dy }


zIndex : Float -> Shape2d -> Shape2d
zIndex z (Shape2d shape) =
    Shape2d { shape | z = z }


setAlpha : Vec3 -> Float -> Vec4
setAlpha =
    Math.Vector3.toRecord >> (\a -> Math.Vector4.vec4 a.x a.y a.z)
