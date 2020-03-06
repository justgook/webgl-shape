# WebGL Shape

2D wrapper for WebGL entities.
Easy way to create 2d shapes (also core for [webgl-playground](https://package.elm-lang.org/packages/justgook/webgl-playground/latest/)): rectangles, circles, sprites and other shapes, group them and reuse textures.

## Usage
```elm
main =
    [ [ rectangle (vec3 1 0 0) 30 30
      , rectangle (vec3 0 1 0) 30 30 |> move 5 5
      , rectangle (vec3 0 0 1) 30 30 |> move 10 10
      ]
        |> group
    ]
        |> WebGL.Shape2d.toEntities Dict.empty
            { width = 100, height = 100 }
        |> Tuple.first
        |> WebGL.toHtml [ width 100, height 100 ]

```
## Rectangle

```elm


rectangle : Vec3 -> Float -> Float -> Shape2d
rectangle color width height =
    Shape2d
        { x = 0
        , y = 0
        , a = 0
        , sx = 1
        , sy = 1
        , o = 1
        , form = Form width height (rectRender color)
        }


rectRender : Vec3 -> Render
rectRender color uP uT opacity =
    WebGL.entity
        vertNone
        fragFill
        mesh
        { color = setAlpha color opacity
        , uP = uP
        , uT = uT
        }


{-| -}
vertNone : Shader { a | aP : Vec2 } { b | uP : Vec2, uT : Vec4 } {}
vertNone =
    [glsl|
        precision mediump float;
        attribute vec2 aP;
        uniform vec4 uT;
        uniform vec2 uP;
        void main () {
            gl_Position = vec4(aP * mat2(uT) + uP, 0., 1.0);
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


group : List Shape2d -> Shape2d
group shapes =
    Shape2d { x = 0, y = 0, a = 0, sx = 1, sy = 1, o = 1, form = Group shapes }


setAlpha : Vec3 -> Float -> Vec4
setAlpha =
    Math.Vector3.toRecord >> (\a -> Math.Vector4.vec4 a.x a.y a.z)


```
