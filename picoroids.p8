pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

left=0
right=1
up=2
down=3
but1=4
but2=5

-- a "shape" is a list of
-- points. the first point is
-- the center of rotation, and
-- the rest of the points form
-- a border between which lines
-- are drawn.

-- return a negated copy of a
-- point.
function npnt(p)
 return {-p[1], -p[2]}
end

-- return a copy of a point.
function copy_pnt(p)
 return {p[1], p[2]}
end

-- return a copy of the  points
-- of a shape.
function points(s)
 local ps = {}
 for i=2, count(s) do
  add(ps, copy_pnt(s[i]))
 end
 return ps
end

-- return x^2
function sq(x)
 return x * x
end

-- return the distance between
-- two points.
function dist(p1,p2)
-- thanks to https://brilliant.org/wiki/distance-formula/
 local x1 = p1[1]
 local y1 = p1[2]
 local x2 = p2[1]
 local y2 = p2[2]
 return sqrt(
  sq(x2-x1) + sq(y2-y1)
 )
end

-- return a copy of a point
-- which has been translated
-- by a vector.
function trans_pnt(p,v)
 return {
  p[1] + v[1],
  p[2] + v[2]
 }
end

-- translate a point in the
-- other direction.
function ntrans_pnt(p,v)
 return trans_pnt(p, npnt(v))
end

-- return a copy of a shape
-- which has been translated
-- by a vector.
function trans_shp(s,v)
 local ts = {}
 for n=1, count(s) do
  add(ts, trans_pnt(s[n],v))
 end
 return ts
end

-- translate a shape in the
-- other direction.
function ntrans_shp(s,v)
 local ts = {}
 for n=1, count(s) do
  add(ts, ntrans_pnt(s[n],v))
 end
 return ts
end

-- return a copy of a point
-- rotated about the origin.
function rot_pnt(p,t)
-- thanks to https://www.lexaloffle.com/bbs/?pid=40230
 local sint = sin(t)
 local cost = cos(t)
 local x = p[1]
 local y = p[2]
 rx = cost*x - sint*y
 ry = sint*x + cost*y
 return {rx, ry} 
end

-- return a rotated copy of a
-- point.
-- p: point to rotate
-- c: center point of rotation
-- t: number of turns
function rot_pnt2(p,c,t)
-- thanks to https://stackoverflow.com/q/2259476/558735
 p = ntrans_pnt(p,c)
 p = rot_pnt(p,t)
 p = trans_pnt(p,c)
 return p
end

-- return a copy of a shape
-- which has been rotated by
-- some number of turns.
function rot_shp(s,t)
 local c = s[1]
 local s2 = {}
 for p in all(s) do
  add(s2, rot_pnt2(p,c,t))
 end
 return s2
end

-- print a point
function print_pnt(p)
 print("point:")
 print(" x: "..p[1]..", y: "..p[2])
end

-- print a shape
function print_shp(s)
 print("shape:")
 print(" center of rotation:")
 print("  x: "..s[1][1]..", y: "..s[1][2])
 local pts = points(s)
 for n=1, count(pts) do
  local a=n
  local b
  if n == count(pts)
  then b=1
  else b=n+1
  end
  print(" line:")
  print("  x: "..pts[a][1]..", y: "..pts[a][2])
  print("  x: "..pts[b][1]..", y: "..pts[b][2])
 end
end

-- draw a shape
function draw_shp(s)
 local pts = points(s)
 for n=1,count(pts) do
  local a = n
  local b
  if n == count(pts)
  then b=1
  else b=n+1
  end
  local ax = pts[a][1]
  local ay = pts[a][2]
  local bx = pts[b][1]
  local by = pts[b][2]
  line(ax,ay,bx,by,8)
 end
end

ship_shp = {
 {0,0},
 {0,-10},
 {10,10},
 {-10,10}
}

function _init()
end

x=63
y=63
rot=0

function _update()
 if btn(left)
 then x -= 1
 end
 if btn(right)
 then x += 1
 end
 if btn(up)
 then y -= 1
 end
 if btn(down)
 then y += 1
 end
 if btn(but1)
 then rot -= 0.01
 end
 if btn(but2)
 then rot += 0.01
 end
end

function _draw()
 cls()
-- print_shp(shape1)
-- draw_shp(shape1)
-- draw_shp(trans_shp(shape1,{63,63}))
-- print(dist({0,0},{3,3}))
-- print_pnt(rot_pnt({2,0},{1,0},0.5))

draw_shp(
 rot_shp(
  trans_shp(ship_shp,{x,y}),
  rot))

-- print("x,y,rot: "..x..","..y..","..rot)
-- p = rot_pnt({x,y},rot)
-- circfill(p[1],p[2],3,8)

-- testrots(rot)
end
