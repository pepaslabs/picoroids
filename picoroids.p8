pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- picoroids: an asteroids
-- clone for pico-8.
-- by jason pepas.
-- https://github.com/pepaslabs/picoroids
-- mit licensed.


--== constants ==--

-- note: constants are prefixed
-- with a "k".

-- button constants
kleft = 0
kright = 1
kup = 2
kdown = 3
kbut1 = 4
kbut2 = 5

-- a "shape" is a list of
-- points. the first point is
-- the center of rotation, and
-- the rest of the points form
-- a border between which lines
-- are drawn.

-- the ship shape
kship_shp = {
 {x=0,y=0},
 {x=5,y=0},
 {x=-3,y=-3},
 {x=-3,y=3}
}

-- the thruster force magnitude
kthrst_mag = 0.05
-- the magnitude of rotation
krot_mag = 0.02

-- the speed of bullets.
kshot_spd = 2.5
-- number of frames a bullet
-- stays on-screen.
kshot_ttl = 30


--== globals ==--

-- note: globals are prefixed
-- with a "g".

-- a ship is a position, a
-- velocity vector, a rotation,
-- a set of shots, and an alive
-- status.
gship = nil

-- the fire button flip-flop.
gfire_ff = false
-- the teleport flip-flop.
gtele_ff = false

-- the "wasted" timer.
-- 90..1: dead
-- 0: respawn
-- -1: alive
gdead_ttl = -1

-- the "win" timer.
-- 90..1: you won
-- 0: respawn
-- -1: playing
gwinner_ttl = -1

-- a "shot" is a position, a
-- velocity vector, and a ttl.

-- the bullets which are
-- currently in-flight.
gshots = {}

-- an "asteroid" is a position,
-- a velocity vector, and a
-- size class.
groids = {}


--== math functions ==--

-- return the square of x.
function sq(x)
 return x * x
end


--== geometry functions ==--

-- return the distance between
-- two points.
function dist(p1, p2)
-- https://en.wikipedia.org/wiki/Euclidean_distance#Two_dimensions
 return sqrt(
  sq(p2.x-p1.x) + sq(p2.y-p1.y)
 )
end


--== vector functions ==--

-- add two vectors together.
function vadd(v1, v2)
 local v3 = {}
 v3.x = v1.x + v2.x
 v3.y = v1.y + v2.y
 return v3
end


--== point functions ==--

-- return a copy of a point.
function copy_pnt(p)
 local p2 = {}
 p2.x = p.x
 p2.y = p.y
 return p2
end

-- return a negated copy of a
-- point.
function npnt(p)
 local p2 = {}
 p2.x = -p.x
 p2.y = -p.y
 return p2
end

-- return a copy of a point
-- which has been translated
-- by a vector.
function trans_pnt(p, v)
 return vadd(p, v)
end

-- translate a point in the
-- other direction.
function ntrans_pnt(p, v)
 return trans_pnt(p, npnt(v))
end

-- return a copy of a point
-- rotated about the origin.
-- p: point to rotate
-- t: number of turns
function rot_pnt(p, t)
-- https://en.wikipedia.org/wiki/Rotation_matrix#In_two_dimensions
 return {
  x = p.x*cos(t) + p.y*sin(t),
  y = p.x*sin(t) - p.y*cos(t)
 }
end

-- return a copy of a point
-- rotated about another point.
-- p: point to rotate
-- c: center point of rotation
-- t: number of turns
function rot_pntc(p, c, t)
-- thanks to https://stackoverflow.com/q/2259476/558735
-- 1. translate point to origin
-- 2. rotate point
-- 3. translate the point back
 local p = ntrans_pnt(p, c)
 p = rot_pnt(p, t)
 p = trans_pnt(p, c)
 return p
end

-- mod a point by 128 (a.k.a.
-- wrap around the edge of the
-- screen).
function mod_pnt(p)
 local p2 = {}
 p2.x = p.x % 128
 p2.y = p.y % 128
 return p2
end

-- print a point.
function print_pnt(p)
 print("point:")
 print(" x: "..p.x..", y: "..p.y)
end


--== shape functions ==--

-- return a copy of the points
-- of a shape.
function shp_points(s)
 local ps = {}
 for i=2, count(s) do
  add(ps, copy_pnt(s[i]))
 end
 return ps
end

-- return a copy of a shape
-- which has been translated
-- by a vector.
function trans_shp(s, v)
 local ts = {}
 for n=1, count(s) do
  add(ts, trans_pnt(s[n], v))
 end
 return ts
end

-- translate a shape in the
-- other direction.
function ntrans_shp(s, v)
 local ts = {}
 for n=1, count(s) do
  add(ts, ntrans_pnt(s[n],v))
 end
 return ts
end

-- return a copy of a shape
-- which has been rotated by
-- some number of turns.
function rot_shp(s, t)
 local c = s[1]
 local s2 = {}
 for p in all(s) do
  add(s2, rot_pntc(p, c, t))
 end
 return s2
end

-- draw a shape.
function draw_shp(s)
 local pts = shp_points(s)
 for n=1, count(pts) do
  local a = n
  local b
  if n == count(pts)
  then b = 1
  else b = n+1
  end
  local pa = pts[a]
  local pb = pts[b]
  line(pa.x,pa.y,pb.x,pb.y,7)
 end
end

-- print a shape.
function print_shp(s)
 print("shape:")
 print(" center of rotation:")
 print("  x: "..s[1].x..", y: "..s[1].y)
 local pts = shp_points(s)
 for n=1, count(pts) do
  local a=n
  local b
  if n == count(pts)
  then b=1
  else b=n+1
  end
  print(" line:")
  print("  x: "..pts[a].x..", y: "..pts[a].y)
  print("  x: "..pts[b].x..", y: "..pts[b].y)
 end
end


--== ship functions ==--

-- return a copy of a ship.
function copy_ship(s)
 local s2 = {}
 s2.pos = s.pos
 s2.vvec = s.vvec
 s2.rot = s.rot
 s2.alive = s.alive
 return s2
end

-- return a moved copy of a
-- ship by applying the
-- velocity vector.
function moved_ship(s)
 local s2 = copy_ship(s)
 s2.pos = mod_pnt(
  vadd(s2.pos, s2.vvec)
 )
 return s2
end

-- return a copy of the ship
-- shape in its current
-- location.
function ship_shape(s)
 return rot_shp(
  trans_shp(kship_shp, s.pos),
  s.rot
 )
end

-- draw a ship.
function draw_ship(s)
 draw_shp(ship_shape(s))
end

-- return a copy of a ship
-- after firing its rear
-- thruster for one frame.
function fire_rthruster(s)
 local s2 = copy_ship(s)
 local thrst_vec = rot_pnt(
  {x=kthrst_mag, y=0},
  s.rot
 )
 s2.vvec = vadd(
  s.vvec, thrst_vec
 )
 return s2
end

-- return a copy of a ship
-- after firing its forward
-- thruster for one frame.
function fire_fthruster(s)
 local s2 = copy_ship(s)
 local nthrst_vec = rot_pnt(
  {x=-kthrst_mag, y=0},
  s.rot
 )
 s2.vvec = vadd(
  s.vvec, nthrst_vec
 )
 return s2
end

-- return a teleported copy of
-- a ship.
function teleport(s)
 s2 = copy_ship(s)
 s2.pos = {
  -- at least 1/2 screen away
  x = s.pos.x + 64 + rnd(63),
  y = s.pos.y + 64 + rnd(63)
 }
 return s2
end


--== shot functions ==--

-- return a copy of a shot.
function copy_shot(s)
 local s2 = {}
 s2.pos = s.pos
 s2.vvec = s.vvec
 s2.ttl = s.ttl
 return s2
end

-- return a copy of the shots.
function copy_shots(ss)
 local ss2 = {}
 for s in all(ss) do
  add(ss2, copy_shot(s))
 end
 return ss2
end

-- draw a shot.
function draw_shot(s)
 pset(s.pos.x, s.pos.y, 7)
end

-- draw the shots.
function draw_shots(shots)
 for s in all(shots) do
  draw_shot(s)
 end
end

-- return a copy of a shot
-- which has been moved.
function moved_shot(s)
 local s2 = copy_shot(s)
 s2.pos = mod_pnt(
  vadd(s.pos, s.vvec)
 )
 s2.ttl -= 1
 return s2
end

-- return a moved copy of
-- the shots.
function moved_shots(shots)
 local shots2 = {}
 for s in all(shots) do
  add(shots2, moved_shot(s))
 end
 return shots2
end

-- return a copy of the shots
-- with the expired shots
-- removed.
function rm_expired_shots(shots)
 local shots2 = {}
 for s in all(shots) do
  if s.ttl > 0 then
   add(shots2, s)
  end
 end
 return shots2
end

-- return a shot fired from a
-- ship.
function spawn_shot(ship)
 local shot = {}
 -- the current bullet position
 shot.pos = copy_pnt(ship.pos)
 -- the bullet velocity vector
 shot.vvec = vadd(
  ship.vvec,
  rot_pnt({x=kshot_spd, y=0}, ship.rot)
 )
 shot.ttl = kshot_ttl
 return shot
end


--== asteroid functions ==--

-- return a copy of an asteroid.
function copy_roid(r)
 local r2 = {}
 r2.pos = r.pos
 r2.vvec = r.vvec
 r2.size = r.size
 return r2
end

-- returns a copy of the
-- asteroids.
function copy_roids(rs)
 local rs2 = {}
 for r in all(rs) do
  add(rs2, copy_roid(r))
 end
 return rs2
end

-- return a moved copy of an
-- asteroid.
function moved_roid(r)
 local r2 = copy_roid(r)
 r2.pos = mod_pnt(
  vadd(r.pos, r.vvec)
 )
 return r2
end

-- return a moved copy of all
-- the asteroids.
function moved_roids(roids)
 local roids2 = {}
 for r in all(roids) do
  add(roids2, moved_roid(r))
 end
 return roids2
end

-- return the radius of an
-- asteroid.
function roid_rad(r)
 return r.size * 3
end

-- draw an asteroid.
function draw_roid(r)
 local rad = roid_rad(r)
 circfill(r.pos.x,r.pos.y,rad,7)
end

-- draw the asteroids.
function draw_roids(roids)
 for r in all(roids) do
  draw_roid(r)
 end
end


--== collision detection ==--

-- return a copy of shots and
-- roids after colliding them.
function collided_shots(shots,roids)
 local ss2 = copy_shots(shots)
 local rs2 = copy_roids(roids)
 for s in all(ss2) do
  for r in all(rs2) do
   local rad = roid_rad(r)
   local d = dist(s.pos, r.pos)
   if d <= rad then
    del(ss2, s)
    del(rs2, r)
   end
  end
 end
 return ss2, rs2
end

-- return a copy of the ship
-- after colliding it with the
-- asteroids.
function collided_ship(ship,roids)
 local s2 = copy_ship(ship)
 local shape = ship_shape(s2)
 for r in all(roids) do
  local rad = roid_rad(r)
  for p in all(shp_points(shape)) do
   local d = dist(r.pos, p)
   if d < rad then
    s2.alive = false
    return s2
   end
  end
 end
 return s2
end


--== user input functions ==--

-- return an updated ship after
-- reading and processing the
-- arrow keys.
function process_dpad(ship)
 local s2 = copy_ship(ship)
 if btn(kleft) then
  s2.rot += krot_mag
 end
 if btn(kright) then
  s2.rot -= krot_mag
 end
 if btn(kup) then
  s2 = fire_rthruster(s2)
 end
 if btn(kdown) then
  s2 = fire_fthruster(s2)
 end
 return s2
end

-- return an updated ship after
-- reading and processing the
-- buttons.
function process_btns(ship,shots)
 local shp2 = copy_ship(ship)
 local shts2 = copy_shots(shots)
 if btn(kbut1) then
  if not gfire_ff then
   gfire_ff = true
   add(
    shts2,
    spawn_shot(shp2)
   )
  end
 else
  gfire_ff = false
 end
 
 if btn(kbut2) then
  if not gtele_ff then
   gtele_ff = true
   shp2 = teleport(shp2)
  end
 else
  gtele_ff = false
 end

 return shp2, shts2
end


--== spawning functions ==--

-- create and return a ship.
function spawn_ship()
 local s = {}
 s.pos = {x=63, y=63}
 s.vvec = {x=0, y=0}
 s.rot = 0.25
 s.alive = true
 return s
end

-- create a new asteroid of a
-- given size class (1-3).
function spawn_roid(size)
 local r = {}
 r.pos = mod_pnt({
  -- try to avoid the center
  x = 96 + rnd(63),
  y = 96 + rnd(63)
 })
 r.vvec = {
  x = 0.5/size + rnd(size) * 0.1/size,
  y = 0
 }
 r.vvec = rot_pnt(
  r.vvec,
  rnd(360)/360.0
 )
 r.size = size
 return r
end

function respawn()
 gship = spawn_ship()
 groids = {
  spawn_roid(3),
  spawn_roid(3),
  spawn_roid(3),
  spawn_roid(2),
  spawn_roid(2),
  spawn_roid(2),
  spawn_roid(1),
  spawn_roid(1),
  spawn_roid(1)
 }
end


--== pico-8 functions ==--

function _init()
 respawn()
end

function _update()
 local shp = copy_ship(gship)
 local shts = copy_shots(gshots)
 local r = copy_roids(groids)

 if shp.alive then
  shp = process_dpad(shp)
  shp,shts = process_btns(shp,shts)
 end

 r = moved_roids(r)
 shts = moved_shots(shts)
 shts = rm_expired_shots(shts)
 shts,r = collided_shots(shts, r)

 if shp.alive then
  shp = moved_ship(shp)
  shp = collided_ship(shp, r)
 end

 gship = shp
 gshots = shts
 groids = r

 if not gship.alive
 then
  if gdead_ttl < 0
  then gdead_ttl = 90
  else
   if gdead_ttl > 0
   then gdead_ttl -= 1
   else
    if gdead_ttl == 0 then
     gdead_ttl = -1
     respawn()
    end
   end
  end
 else
  if #groids == 0 then
   if gwinner_ttl < 0
   then gwinner_ttl = 90
   else
    if gwinner_ttl > 0
    then gwinner_ttl -= 1
    else
     if gwinner_ttl == 0 then
      gwinner_ttl = -1
      respawn()
     end
    end
   end
  end
 end
end

function _draw()
 cls()
 rectfill(0,0,127,127,1)
 if gship.alive then
  draw_ship(gship)
 end
 draw_shots(gshots)
 draw_roids(groids)
 if gdead_ttl > 0 then
  print("wasted", 51, 61, 8)
 else
  if gwinner_ttl > 0 then
   print("a winner is you", 33, 61, 11)
  end
 end
end
