######################################
# smartSlider Module  ################
######################################
# Universal multifunctional slider ###
######################################


angular
        .module 'smartSlider.module', []
            
        # mouse service for detecting mouse events
        .factory 'mouseService', ($window, $rootScope) ->
          
          # element with mousedown event
          selected = null
          sId = null

          # listeners
          angular.element($window).on 'touchend mouseup', (ev) ->
            $rootScope.$broadcast 'selectedreleased'
            selected = null
            sId = null
          angular.element($window).on 'touchmove mousemove', (ev) ->
            ev.stopPropagation()
            if selected
              if ev.targetTouches && ev.type == 'touchmove'
                $rootScope.$broadcast 'moveselected', ev.targetTouches[0].pageX
              else
                $rootScope.$broadcast 'moveselected', ev.pageX
              
          
          # return
          selected: (element, id) ->
            if element?
              sId = id
              return selected = element
            else
              return [selected, sId]



        # MAIN DIRECTIVE
        .directive 'smartSlider', (mouseService) ->
          scope:
            min: '=?'
            max: '=?'
            step: '=?'
            model: '=?'
            limits: '=?'
            sections: '=?'
            tooltip: '=?'

          restrict: 'E'
          templateUrl: "slider.tmp.html"
          replace: true

          controller: ($scope, $element, $timeout) ->
            
            s = $scope
                        

            # init phase
            ############
            # default values
            if !s.min then s.min = 0
            if !s.max then s.max = 100
            if !s.step then s.step = 1
            

            # window events listener
            s.$on 'moveselected', (ev, pageX, $rootScope) ->
              if s.$id == mouseService.selected()[1]
                # define elements
                targetScope = ev.targetScope
                handle = mouseService.selected()[0]
                wrap = handle.parent()
                # get wrapper offset
                offset = s.getOffset(wrap)
                offset.percentage = offset.width / 100
                percInPx = ( (pageX - offset.left) / offset.percentage)
                # apply new value based on handle position
                s.model = s.getValueOfPercentage(percInPx, offset)
                s.$apply()


            # backup $watcher which keeps the values in the defined range
            s.$watch 'model', (n, o) ->
              if n == undefined
                s.model = s.min

              # prevent non Numbers to be added
              if isNaN(s.model)
                s.model = s.min
              
              s.model = parseInt(s.model)

              # limit range - (auto range setter)
              if n < s.min then s.model = s.min
              if n > s.max then s.model = s.max
              s.model = s.roundNum s.model, s.step, 0
              

              # tooltip show/hide
              # check if tooltip is present
              if angular.isObject(s.tooltip)
                angular.forEach s.tooltip, (value, key) ->
                  if parseInt(key) <= s.model
                    s.showTooltip = value
                  else s.showTooltip = null
                

              # init code segment for sections (if present)
              if o!=undefined or n!=undefined and s.sections and s.breakpoints == undefined
                s.breakpoints = []
                stepDif = s.max / s.sections
                for num in [1..s.sections]
                  if (num*stepDif) > s.min
                    s.breakpoints.push s.roundNum (stepDif * num), s.step, 0
          

            # f() for rounding numbers
            s.roundNum = (number, increment, offset) ->
              Math.round((number - offset) / increment) * increment + offset

            # f() for getting offset of an element in !pixels!
            s.getOffset = (element) ->
              offset = element[0].getBoundingClientRect()
              return offset
            
            # helper methods
            s.getPercentage = (n) ->
              onePerc = (s.max - s.min) / 100
              return ( (n-s.min) / onePerc ) + "%"
            s.getValueOfPercentage = (perc, offset) ->
              if s.max > s.min
                range = s.max - s.min
              else
                range = s.min - s.max
              
              if offset?
                return s.roundNum(((perc / 100) * range) + s.min, s.step, 0)
            s.goTo = (value) ->
              if value?
                s.model = value
              return

            # slider buttons methods
            s.add = (step) ->
              s.model += step
              if s.model > s.max
                s.model = s.max
            s.subtract = (step) ->
              s.model -= step
              if s.model < s.min
                s.model = s.min

        
        .directive 'stopPropagation', () ->
          return (s,e,a) ->
            e.bind 'click mousedown touchstart', (e) ->
              e.stopPropagation()


        # directive helper that returns percentage after click
        .directive 'detectClick', () ->
          return (s,e,a) ->
            e.bind 'click', (ev) ->
              offset = s.getOffset(e)
              offset.percentage = offset.width / 100
              percInPx = ( (ev.pageX - offset.left) / offset.percentage)
              s.model = s.getValueOfPercentage(percInPx, offset)
              s.$apply()
            
        
        # slider handle directive
        .directive 'smartHandle', (mouseService, $rootScope) ->
          return (s,e,a) ->
            
            e.bind 'touchstart mousedown', (ev) ->
              ev.stopPropagation()
              # send object & s.$id to service
              mouseService.selected(e, s.$id)
              s.$apply()



