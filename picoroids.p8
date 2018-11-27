pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- picoroids: an asteroids
-- clone for pico-8.
-- by jason pepas.
-- github/pepaslabs/picoroids
-- mit licensed.

--== globals ==--

-- button constants
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

-- the ship shape
ship_shp = {
 {0,0},
 {5,0},
 {-3,-3},
 {-3,3}
}

-- the ship's position {x,y}
ship_pos={63,63}
-- the ship's rotation
ship_rot=0.25
-- the thruster force magnitude
thrst_mag=0.05
-- the magnitude of rotation
rot_mag=0.02
-- the ship's velocity vector
ship_vvec={0,0}
-- the fire button flip-flop
fire_ff=false
-- the teleport flip-flop
tele_ff=false
-- whether the player is alive
alive=true

-- a "shot" is a position, a
-- velocity vector, and a ttl.

-- the speed of bullets.
shot_spd=2.5
-- number of frames a bullet
-- stays on-screen.
shot_ttl=30

-- the bullets which are
-- currently in-flight.
shots={}

-- an "asteroid" is a position,
-- a velocity vector, and a
-- size class.
roids={}


--== functions ==--

-- return a negated copy of a
-- point.
function npnt(p)
 return {-p[1], -p[2]}
end

-- return a copy of a point.
function copy_pnt(p)
 return {p[1], p[2]}
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
  line(ax,ay,bx,by,7)
 end
end

-- add two vectors together
function vadd(v1,v2)
 return {
  v1[1] + v2[1],
  v1[2] + v2[2]
 }
end

-- mod a point by 128
function mod_pnt(p)
 return {p[1]%128,p[2]%128}
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
   trans_shp(ship_shp,ship_pos),
   ship_rot
  )
 )
end

-- fire the thruster for one
-- frame, updating the ship's
-- velocity vector.
function fire_rthruster()
 local thrst_v = {thrst_mag, 0}
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
 local thrst_v = {-thrst_mag, 0}
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
  ship_pos[1] + 64 + rnd(63),
  ship_pos[2] + 64 + rnd(63)
 }
end

function draw_shot(s)
 local pos = s[1]
 pset(pos[1],pos[2],7)
end

function draw_shots(s)
 for s in all(shots) do
  draw_shot(s)
 end
end

-- returns a copy of a shot
-- which has been moved.
function move_shot(s)
 local pos = s[1]
 local vvec = s[2]
 local ttl = s[3]
 pos = mod_pnt(vadd(pos, vvec))
 shot = {
   pos,
   vvec,
   ttl-1
 }
 return shot
end

function move_shots()
 shots2={}
 for s in all(shots) do
  add(shots2, move_shot(s))
 end
 shots = shots2
end

-- filter out the shots which
-- have been on-screen for too
-- long.
function expire_shots()
 shots2={}
 for s in all(shots) do
  local pos = s[1]
  local vvec = s[2]
  local ttl = s[3]
  if ttl > 0 then
   add(shots2,s)
  end
 end
 shots = shots2
end

-- fire a new bullet.
function shoot()
 -- the current bullet position
 local pos = {
   ship_pos[1], ship_pos[2]
 }
 -- the bullet velocity vector
 local vvec = {shot_spd, 0}
 vvec = rot_pnt(
  vvec, ship_rot
 )
 vvec = vadd(
  ship_vvec, vvec
 )

 local shot = {
  pos,
  vvec,
  shot_ttl
 }
 add(shots, shot)
end

function spawn_roid(size)
 pos = mod_pnt({
  96 + rnd(63),
  96 + rnd(63)
 })
 vvec = {
   0.5/size + rnd(size)*0.1/size,
   0
 }
 vvec = rot_pnt(vvec,rnd(100)/100.0)
 local roid = {
  pos,
  vvec,
  size
 }
 add(roids,roid)
end

-- returns a moved copy of an
-- asteroid.
function move_roid(r)
 local pos = r[1]
 local vvec = r[2]
 pos = mod_pnt(vadd(pos, vvec))
 return {
   pos,
   vvec,
   r[3]
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
 return r[3] * 3
end

-- draw an asteroid.
function draw_roid(r)
 pos = r[1]
 size_class = r[3]
 rad = roidrad(r)
 circfill(pos[1],pos[2],rad,7)
end

-- draw all of the asteroids.
function draw_roids()
 for r in all(roids) do
  draw_roid(r)
 end
end

function process_dpad()
 if btn(left) then
  ship_rot += rot_mag
 end
 if btn(right) then
  ship_rot -= rot_mag
 end
 if btn(up) then
  fire_rthruster()
 end
 if btn(down) then
  fire_fthruster()
 end
end

function process_btns()
 if btn(but1) then
  if not fire_ff then
   fire_ff=true
   shoot()
  end
 else
  fire_ff=false
 end

 if btn(but2) then
  if not tele_ff then
   tele_ff=true
   teleport()
  end
 else
  tele_ff=false
 end
end

-- detect collisions between
-- shots and asteroids.
function collide_shots()
 for s in all(shots) do
  for r in all(roids) do
   local spos = s[1]
   local rpos = r[1]
   local rad = roidrad(r)
   local d = dist(spos,rpos)
   if d <= rad then
    del(shots,s)
    del(roids,r)
   end
  end
 end
end

function collide_ship()
 local ship = rot_shp(
  trans_shp(ship_shp,ship_pos),
  ship_rot
 )
 for r in all(roids) do
  local rpos = r[1]
  local rad = roidrad(r)
  for p in all(points(ship)) do
   local d = dist(rpos,p)
   if d < rad then
    alive = false
    return nil
   end
  end
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
  collide_ship()
  move_ship()
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
