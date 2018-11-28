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

-- the ship's position
ship_pos = {x=63, y=63}
-- the ship's rotation
ship_rot = 0.25
-- the ship's velocity vector
ship_vvec = {x=0,y=0}
-- the fire button flip-flop
fire_ff = false
-- the teleport flip-flop
tele_ff = false
-- whether the player is alive
alive = true

-- a "shot" is a position, a
-- velocity vector, and a ttl.

-- the bullets which are
-- currently in-flight.
shots = {}

-- an "asteroid" is a position,
-- a velocity vector, and a
-- size class.
roids = {}


--== functions ==--

-- return a negated copy of a
-- point.
function npnt(p)
 return {x=-p.x, y=-p.y}
end

-- return a copy of a point.
function copy_pnt(p)
 return {x=p.x, y=p.y}
end

-- return a copy of the points
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
 return sqrt(
  sq(p2.x-p1.x) + sq(p2.y-p1.y)
 )
end

-- return a copy of a point
-- which has been translated
-- by a vector.
function trans_pnt(p,v)
 return {
  x = p.x + v.x,
  y = p.y + v.y
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
 rx = cost * p.x - sint * p.y
 ry = sint * p.x + cost * p.y
 return {x=rx, y=ry}
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
 print(" x: "..p.x..", y: "..p.y)
end

-- print a shape
function print_shp(s)
 print("shape:")
 print(" center of rotation:")
 print("  x: "..s[1].x..", y: "..s[1].y)
 local pts = points(s)
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
  local pa = pts[a]
  local pb = pts[b]
  line(pa.x,pa.y,pb.x,pb.y,7)
 end
end

-- add two vectors together
function vadd(v1,v2)
 return {
  x = v1.x + v2.x,
  y = v1.y + v2.y
 }
end

-- mod a point by 128
function mod_pnt(p)
 return {
  x = p.x % 128,
  y = p.y % 128
 }
end

-- move the ship by applying
-- the velocity vector.
function move_ship()
 ship_pos = mod_pnt(
  vadd(
   ship_pos, ship_vvec
  )
 )
end

function draw_ship()
 draw_shp(
  rot_shp(
   trans_shp(kship_shp,ship_pos),
   ship_rot
  )
 )
end

-- fire the thruster for one
-- frame, updating the ship's
-- velocity vector.
function fire_rthruster()
 local thrst_v = {
  x = kthrst_mag,
  y = 0
 }
 thrst_v = rot_pnt(
  thrst_v, ship_rot
 )
 ship_vvec = vadd(
  thrst_v, ship_vvec
 )
end

-- fire the front-facing
-- thruster, accellerating the
-- ship backward.
function fire_fthruster()
 local thrst_v = {
  x = -kthrst_mag,
  y = 0
 }
 thrst_v = rot_pnt(
  thrst_v, ship_rot
 )
 ship_vvec = vadd(
  thrst_v, ship_vvec
 )
end

-- teleport the ship to a
-- random location.
function teleport()
 ship_pos = {
  -- at least 1/2 screen away
  x = ship_pos.x + 64 + rnd(63),
  y = ship_pos.y + 64 + rnd(63)
 }
end

function draw_shot(s)
 pset(s.pos.x, s.pos.y, 7)
end

function draw_shots(s)
 for s in all(shots) do
  draw_shot(s)
 end
end

-- returns a copy of a shot
-- which has been moved.
function move_shot(s)
 local pos = mod_pnt(
  vadd(s.pos, s.vvec)
 )
 shot = {
  pos = pos,
  vvec = s.vvec,
  ttl = s.ttl - 1
 }
 return shot
end

-- move all of the shots.
function move_shots()
 shots2 = {}
 for s in all(shots) do
  add(shots2, move_shot(s))
 end
 shots = shots2
end

-- filter out the shots which
-- have been on-screen for too
-- long.
function expire_shots()
 shots2 = {}
 for s in all(shots) do
  if s.ttl > 0 then
   add(shots2, s)
  end
 end
 shots = shots2
end

-- fire a new bullet.
function shoot()
 -- the current bullet position
 local pos = copy_pnt(ship_pos)
 -- the bullet velocity vector
 local vvec = {
  x = kshot_spd,
  y = 0
 }
 vvec = rot_pnt(
  vvec, ship_rot
 )
 vvec = vadd(
  ship_vvec, vvec
 )

 local shot = {
  pos = pos,
  vvec = vvec,
  ttl = kshot_ttl
 }
 add(shots, shot)
end

-- create a new asteroid of a
-- given size class (1-3)
function spawn_roid(size)
 pos = mod_pnt({
  -- try to avoid the center
  x = 96 + rnd(63),
  y = 96 + rnd(63)
 })
 vvec = {
  x = 0.5/size + rnd(size) * 0.1/size,
  y = 0
 }
 vvec = rot_pnt(
  vvec,
  rnd(100)/100.0
 )
 local roid = {
  pos = pos,
  vvec = vvec,
  size = size
 }
 add(roids,roid)
end

-- returns a moved copy of an
-- asteroid.
function move_roid(r)
 local pos = mod_pnt(
  vadd(r.pos, r.vvec)
 )
 return {
  pos = pos,
  vvec = r.vvec,
  size = r.size
 }
end

-- move all of the asteroids.
function move_roids()
 roids2 = {}
 for r in all(roids) do
  add(roids2, move_roid(r))
 end
 roids = roids2
end

-- return the radius of an
-- asteroid.
function roidrad(r)
 return r.size * 3
end

-- draw an asteroid.
function draw_roid(r)
 rad = roidrad(r)
 circfill(r.pos.x,r.pos.y,rad,7)
end

-- draw all of the asteroids.
function draw_roids()
 for r in all(roids) do
  draw_roid(r)
 end
end

-- detect collisions between
-- shots and asteroids.
function collide_shots()
 for s in all(shots) do
  for r in all(roids) do
   local rad = roidrad(r)
   local d = dist(s.pos,r.pos)
   if d <= rad then
    del(shots,s)
    del(roids,r)
   end
  end
 end
end

-- detect collisions between
-- asteroids and the ship.
function collide_ship()
 local ship = rot_shp(
  trans_shp(kship_shp,ship_pos),
  ship_rot
 )
 for r in all(roids) do
  local rad = roidrad(r)
  for p in all(points(ship)) do
   local d = dist(r.pos, p)
   if d < rad then
    alive = false
    return nil
   end
  end
 end
end

-- read and process the dpad.
function process_dpad()
 if btn(kleft) then
  ship_rot += krot_mag
 end
 if btn(kright) then
  ship_rot -= krot_mag
 end
 if btn(kup) then
  fire_rthruster()
 end
 if btn(kdown) then
  fire_fthruster()
 end
end

-- read and process the buttons.
function process_btns()
 if btn(kbut1) then
  if not fire_ff then
   fire_ff=true
   shoot()
  end
 else
  fire_ff=false
 end
 
 if btn(kbut2) then
  if not tele_ff then
   tele_ff=true
   teleport()
  end
 else
  tele_ff=false
 end
end

function _init()
 spawn_roid(3)
 spawn_roid(3)
 spawn_roid(3)
 spawn_roid(2)
 spawn_roid(2)
 spawn_roid(2)
 spawn_roid(1)
 spawn_roid(1)
 spawn_roid(1)
end

function _update()
 if alive then
  process_dpad()
  process_btns()
 end
 move_roids()
 move_shots()
 expire_shots()
 collide_shots()
 if alive then
  move_ship()
  collide_ship()
 end
end

function _draw()
 cls()
 rectfill(0,0,127,127,1)
 if alive then
  draw_ship()
 end
 draw_shots()
 draw_roids()
 if not alive then
  print("wasted",51,61,8)
 end
end
