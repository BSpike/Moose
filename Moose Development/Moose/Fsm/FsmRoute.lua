--- (SP) (MP) (FSM) Route AI or players through waypoints or to zones.
-- 
-- ===
-- 
-- # @{#FSM_ROUTE} FSM class, extends @{Fsm.Fsm#FSM_PROCESS}
-- 
-- ## FSM_ROUTE state machine:
-- 
-- This class is a state machine: it manages a process that is triggered by events causing state transitions to occur.
-- All derived classes from this class will start with the class name, followed by a \_. See the relevant derived class descriptions below.
-- Each derived class follows exactly the same process, using the same events and following the same state transitions, 
-- but will have **different implementation behaviour** upon each event or state transition.
-- 
-- ### FSM_ROUTE **Events**:
-- 
-- These are the events defined in this class:
-- 
--   * **Start**:  The process is started. The process will go into the Report state.
--   * **Report**: The process is reporting to the player the route to be followed.
--   * **Route**: The process is routing the controllable.
--   * **Pause**: The process is pausing the route of the controllable.
--   * **Arrive**: The controllable has arrived at a route point.
--   * **More**:  There are more route points that need to be followed. The process will go back into the Report state.
--   * **NoMore**:  There are no more route points that need to be followed. The process will go into the Success state.
-- 
-- ### FSM_ROUTE **Event methods**:
-- 
-- Event methods are available (dynamically allocated by the state machine), that accomodate for state transitions occurring in the process.
-- There are two types of event methods, which you can use to influence the normal mechanisms in the state machine:
-- 
--   * **Immediate**: The event method has exactly the name of the event.
--   * **Delayed**: The event method starts with a __ + the name of the event. The first parameter of the event method is a number value, expressing the delay in seconds when the event will be executed. 
-- 
-- ### FSM_ROUTE **States**:
-- 
--   * **None**: The controllable did not receive route commands.
--   * **Arrived (*)**: The controllable has arrived at a route point.
--   * **Aborted (*)**: The controllable has aborted the route path.
--   * **Routing**: The controllable is understay to the route point.
--   * **Pausing**: The process is pausing the routing. AI air will go into hover, AI ground will stop moving. Players can fly around.
--   * **Success (*)**: All route points were reached. 
--   * **Failed (*)**: The process has failed.
--   
-- (*) End states of the process.
--   
-- ### FSM_ROUTE state transition methods:
-- 
-- State transition functions can be set **by the mission designer** customizing or improving the behaviour of the state.
-- There are 2 moments when state transition methods will be called by the state machine:
-- 
--   * **Before** the state transition. 
--     The state transition method needs to start with the name **OnBefore + the name of the state**. 
--     If the state transition method returns false, then the processing of the state transition will not be done!
--     If you want to change the behaviour of the AIControllable at this event, return false, 
--     but then you'll need to specify your own logic using the AIControllable!
--   
--   * **After** the state transition. 
--     The state transition method needs to start with the name **OnAfter + the name of the state**. 
--     These state transition methods need to provide a return value, which is specified at the function description.
-- 
-- ===
-- 
-- # 1) @{#FSM_ROUTE_ZONE} class, extends @{Fsm.Route#FSM_ROUTE}
-- 
-- The FSM_ROUTE_ZONE class implements the core functions to route an AIR @{Controllable} player @{Unit} to a @{Zone}.
-- The player receives on perioding times messages with the coordinates of the route to follow. 
-- Upon arrival at the zone, a confirmation of arrival is sent, and the process will be ended.
-- 
-- # 1.1) FSM_ROUTE_ZONE constructor:
--   
--   * @{#FSM_ROUTE_ZONE.New}(): Creates a new FSM_ROUTE_ZONE object.
-- 
-- ===
-- 
-- @module Route


do -- FSM_ROUTE

  --- FSM_ROUTE class
  -- @type FSM_ROUTE
  -- @field Tasking.Task#TASK TASK
  -- @field Wrapper.Unit#UNIT ProcessUnit
  -- @field Core.Zone#ZONE_BASE TargetZone
  -- @extends Fsm.Fsm#FSM_PROCESS
  FSM_ROUTE = { 
    ClassName = "FSM_ROUTE",
  }
  
  
  --- Creates a new routing state machine. The process will route a CLIENT to a ZONE until the CLIENT is within that ZONE.
  -- @param #FSM_ROUTE self
  -- @return #FSM_ROUTE self
  function FSM_ROUTE:New()

    -- Inherits from BASE
    local self = BASE:Inherit( self, FSM_PROCESS:New( "FSM_ROUTE" ) ) -- Fsm.Fsm#FSM_PROCESS
 
    self:AddTransition( "None", "Start", "Routing" )
    self:AddTransition( "*", "Report", "Reporting" )
    self:AddTransition( "*", "Route", "Routing" )
    self:AddTransition( "Routing", "Pause", "Pausing" )
    self:AddTransition( "*", "Abort", "Aborted" )
    self:AddTransition( "Routing", "Arrive", "Arrived" )
    self:AddTransition( "Arrived", "Success", "Success" )
    self:AddTransition( "*", "Fail", "Failed" )
    self:AddTransition( "", "", "" )
    self:AddTransition( "", "", "" )
 
    self:AddEndState( "Arrived" )
    self:AddEndState( "Failed" )
    
    self:SetStartState( "None" )  
  
    return self
  end

  --- Task Events

  --- StateMachine callback function
  -- @param #FSM_ROUTE self
  -- @param Wrapper.Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function FSM_ROUTE:onafterStart( ProcessUnit, Event, From, To )
  

    self:__Route( 1 )
  end
  
  --- Check if the controllable has arrived.
  -- @param #FSM_ROUTE self
  -- @param Wrapper.Controllable#CONTROLLABLE ProcessUnit
  -- @return #boolean
  function FSM_ROUTE:onfuncHasArrived( ProcessUnit )
    return false
  end
  
  --- StateMachine callback function
  -- @param #FSM_ROUTE self
  -- @param Wrapper.Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function FSM_ROUTE:onbeforeRoute( ProcessUnit, Event, From, To )
  
    if ProcessUnit:IsAlive() then
      local HasArrived = self:onfuncHasArrived( ProcessUnit ) -- Polymorphic
      if self.DisplayCount >= self.DisplayInterval then
        self:T( { HasArrived = HasArrived } )
        if not HasArrived then
          self:__Report( 1 )
        end
        self.DisplayCount = 1
      else
        self.DisplayCount = self.DisplayCount + 1
      end
      
      self:T( { DisplayCount = self.DisplayCount } )
      
      if HasArrived then
        self:__Arrive( 1 )
      else
        self:__Route( 1 )
      end
    
      return HasArrived -- if false, then the event will not be executed...
    end
    
    return false
    
  end

end -- FSM_ROUTE



do -- FSM_ROUTE_ZONE

  --- FSM_ROUTE_ZONE class
  -- @type FSM_ROUTE_ZONE
  -- @field Tasking.Task#TASK TASK
  -- @field Wrapper.Unit#UNIT ProcessUnit
  -- @field Core.Zone#ZONE_BASE TargetZone
  -- @extends #FSM_ROUTE
  FSM_ROUTE_ZONE = { 
    ClassName = "FSM_ROUTE_ZONE",
  }


  --- Creates a new routing state machine. The task will route a controllable to a ZONE until the controllable is within that ZONE.
  -- @param #FSM_ROUTE_ZONE self
  -- @param Core.Zone#ZONE_BASE TargetZone
  function FSM_ROUTE_ZONE:New( TargetZone )
    local self = BASE:Inherit( self, FSM_ROUTE:New() ) -- #FSM_ROUTE_ZONE

    self.TargetZone = TargetZone
    
    self.DisplayInterval = 30
    self.DisplayCount = 30
    self.DisplayMessage = true
    self.DisplayTime = 10 -- 10 seconds is the default
    
    return self
  end
  
  function FSM_ROUTE_ZONE:Init( FsmRoute )
  
    self.TargetZone = FsmRoute.TargetZone
    self.DisplayInterval = 30
    self.DisplayCount = 30
    self.DisplayMessage = true
    self.DisplayTime = 10 -- 10 seconds is the default
  end  
  
  --- Method override to check if the controllable has arrived.
  -- @param #FSM_ROUTE self
  -- @param Wrapper.Controllable#CONTROLLABLE ProcessUnit
  -- @return #boolean
  function FSM_ROUTE_ZONE:onfuncHasArrived( ProcessUnit )

    if ProcessUnit:IsInZone( self.TargetZone ) then
      local RouteText = "You have arrived within the zone."
      self:Message( RouteText )
    end

    return ProcessUnit:IsInZone( self.TargetZone )
  end
  
  --- Task Events
  
  --- StateMachine callback function
  -- @param #FSM_ROUTE_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function FSM_ROUTE_ZONE:onenterReporting( ProcessUnit, Event, From, To )
  
    local ZoneVec2 = self.TargetZone:GetVec2()
    local ZonePointVec2 = POINT_VEC2:New( ZoneVec2.x, ZoneVec2.y )
    local TaskUnitVec2 = ProcessUnit:GetVec2()
    local TaskUnitPointVec2 = POINT_VEC2:New( TaskUnitVec2.x, TaskUnitVec2.y )
    local RouteText = "Route to " .. TaskUnitPointVec2:GetBRText( ZonePointVec2 ) .. " km to target."
    self:Message( RouteText )
  end

end -- FSM_ROUTE_ZONE
