/* 
 * Copyright (c) 2006 Allurent, Inc.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the
 * Software, and to permit persons to whom the Software is furnished
 * to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
 * OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
 
package urlkit.rules
{
import flash.events.*;
import mx.events.*;
import mx.controls.*;
import mx.containers.*;

/**
 * Subclass of UrlValueRule which provides automatic linkage of the
 * value to the 'label' property of an associated navigation
 * container's selectedChild.  This is to be used when a URL component
 * is mapped to the label of the container's selected child.
 */

public class UrlNavigatorRule extends UrlValueRule
{
    // The navigation component that is coupled to this rule's value
    private var _navigator:Object;
    
    // a flag indicating that our navigation control exists
    private var _controlInitialized:Boolean = false;
    
    // Storage for a bindable property exposing a child rule
    // associated with the currently selected child of the navigator.
    private var _navigatorChildRule:IUrlRule;

    /**
     * The name of a property which, when accessed on a selected child of
     * the associated navigator, will yield an IUrlRule instance mapping
     * a URL fragment to that child's state.  The default value is "urls".
     */
    [Bindable]
    public var navigatorChildRuleName:String = "urls";

    /**
     * The current child rule of the navigator's selected child's IUrlRule.
     * @see #navigatorChildRuleName
     */
    [Bindable]
    public var navigatorChildRule:IUrlRule;

    /**
     * The name of a property of each selected child of the associated navigator,
     * which determines the String value of this rule corresponding to that child.
     */
    [Bindable]
    public var urlField:String = "label";

    /**
     * A flag indicating that the child's label property should be used as the title component
     * of this rule.
     */
    [Bindable]
    public var useChildLabelForTitle:Boolean = false;

    public function UrlNavigatorRule()
    {
    }
    
    /**
     * Override the superclass commitBrowserChange() function
     * to force the navigator component's index to correspond to the
     * rule's string value as determined from the URL.  Also updates
     * the navigatorChildRule property.
     */
    override protected function commitBrowserChange():void
    {
		super.commitBrowserChange();
        updateNavContainerIndex();	
    }

    /**
     * Override the computeApplicationState() function to update
     * this UrlValueRule's string value from the navigator prior to
     * URL determination.  Also updates the navigatorChildRule property.
     * 
     */
    override protected function computeApplicationState():void
    {
        updateStringValue();
        super.computeApplicationState();
    }
    
    [Bindable("titleChange")]
    override public function get title():String
    {
        return super.title || (useChildLabelForTitle && _navigator != null 
                            ? _navigator.selectedChild.label 
                            : null);
    }

    override public function get active():Boolean
    {
    	return super.active && _navigator != null
    }

    /**
     * Check this rule to determine whether it's ready.  Readiness of a
     * navigator rule requires that its navigator be present and completely initialized.
     */
    override protected function checkReadiness(e:Event):void
    {
        if (!_controlInitialized)
        {
            ready = false;
        }
        else
        {
            super.checkReadiness(e);
        }
    }
    /**
     * Set a component whose class extends NavBar as this rule's navigator.
     */
    public function set navBar(n:NavBar):void
    {
        navContainer = n;
    }

    public function get navBar():NavBar
    {
        return navContainer as NavBar;
    }

    /**
     * Set a component whose class extends Accordion as this rule's navigator.
     */
    public function set accordion(n:Accordion):void
    {
        navContainer = n;
    }

    public function get accordion():Accordion
    {
        return navContainer as Accordion;
    }

    /**
     * Set a component whose class extends TabNavigator as this rule's navigator.
     */
    public function set tabNavigator(n:TabNavigator):void
    {
        navContainer = n;
    }

    public function get tabNavigator():TabNavigator
    {
        return navContainer as TabNavigator;
    }

    /**
     * Set a component whose class extends ViewStack as this rule's navigator.
     */
    public function set viewStack(n:ViewStack):void
    {
        navContainer = n;
    }
    
    public function get viewStack():ViewStack
    {
        return navContainer as ViewStack;
    }

    /**
     * Set this rule's navigator component, initializing all listeners
     * and rule state appropriately.  A number of events dispatched by
     * navigators need to be monitored in order for this rule to function.
     * 
     * @param n the component instance to be treated as this rule's navigator/
     * 
     */
    protected function set navContainer(n:Object):void
    {
        if (_navigator == n)
        {
            return;
        }

        if (_navigator != null)
        {
            _navigator.removeEventListener(FlexEvent.VALUE_COMMIT, onNavigatorChange);
            _navigator.removeEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
            _navigator.removeEventListener(ChildExistenceChangedEvent.CHILD_ADD, onNavigatorChange);
            _navigator.removeEventListener(ChildExistenceChangedEvent.CHILD_REMOVE, onNavigatorChange);
        }
        
        _navigator = n;
        _controlInitialized = false;
        
        if (_navigator != null)
        {
            _navigator.addEventListener(FlexEvent.VALUE_COMMIT, onNavigatorChange);
            _navigator.addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
            _navigator.addEventListener(ChildExistenceChangedEvent.CHILD_ADD, onNavigatorChange);
            _navigator.addEventListener(ChildExistenceChangedEvent.CHILD_REMOVE, onNavigatorChange);
            _controlInitialized = _navigator.initialized;
            checkReadiness(null);
            if (ready)
            {
                invalidateState();
            }
        }
    }

    protected function get navContainer():Object
    {
        return _navigator;
    }

    /**
     * Handle the initialization of the navigator by appropriately
     * syncing our rule value to its state.
     */
    protected function onCreationComplete(event:Event):void
    {
        if (_controlInitialized == false)
        {
            _controlInitialized = true;
            checkReadiness(event);
            invalidateState();
        }
    }

    /**
     * Update the navigator's selected child index to our rule's string value
     * in response to a browser change or initialization action.  Also recompute the child rule.
     */
    protected function updateNavContainerIndex():void
    {
		if (_navigator != null  && _navigator.numChildren > 0)
		{
            for (var childNo:int = 0; childNo < _navigator.numChildren; ++childNo)
            {
                var childLabel:String = _navigator is NavBar
                                            ? _navigator.getChildAt(childNo)[_navigator.labelField]
                                            : _navigator.getChildAt(childNo)[urlField];
                
                if (childLabel == stringValue)
                {
                    if (_navigator.selectedIndex != childNo)
                    {
                    	_navigator.selectedIndex = childNo;
                    }
                    
                    updateNavigatorChildRule();
                    
                    break;
                }
            }
		}
    }
    
    protected function updateNavigatorChildRule():void
    {
        if (navigatorChildRuleName in _navigator.selectedChild)
            navigatorChildRule = _navigator.selectedChild[navigatorChildRuleName];
        else
            navigatorChildRule = null;
    }
    
    /**
     * If the navigator changes in any of various ways, then we have to adjust our state
     * appropriately.
     * @param event
     */
    private function onNavigatorChange(event:Event):void
    {
        invalidateState();
    }

    /**
     * Set the stringValue of this rule to the appropriate value for the selected
     * child of this navigator, and update the child rule.
     */
    private function updateStringValue():void
    {
	    stringValue = _navigator.selectedIndex >= 0 
	                    ? _navigator is NavBar
	                        ? _navigator.getChildAt(_navigator.selectedIndex)[_navigator.labelField]
	                        : _navigator.getChildAt(_navigator.selectedIndex)[urlField]
	                    : "";

	    updateNavigatorChildRule();
    }

}
}
