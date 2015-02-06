
function cc.p(_x,_y)
    if nil == _y then
         return { x = _x.x, y = _x.y }
    else
         return { x = _x, y = _y }
    end
end
