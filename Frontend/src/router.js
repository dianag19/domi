import React, { Component } from 'react';
import './App.css';
import {
  BrowserRouter as Router,
  Route,
  Link,
  Redirect,
  withRouter,
  Switch
} from "react-router-dom";
import Welcome from './routes/welcome'
import Signin from './routes/signin'
import NavbarBlack from './components/navbarBlack'
import Profile from './routes/profile'
import { Provider } from 'react-redux'
import store from './redux/store'
import isAuthenticated from './redux/actions/isAuthenticated';

class Routes extends Component {

    constructor(props){
      super(props);
      /*this.state = {
        showLoginForm: false
      }*/
      //this.onPressShow = this.onPressShow.bind(this);
      //this.onPressClose = this.onPressClose.bind(this);  
    }
    /*
    onPressShow(event){
      this.setState({
        showLoginForm:true
      })       
    }

    onPressClose(event){
      this.setState({
        showLoginForm:false
      })   
    }*/

    render(){
        return(
          <Provider store={store}>
            <Router>
                <div className="App-Router">
                <NavbarBlack/>
                  <Switch className="App-Switch">
                    <Route path="/" exact={true} component={Welcome} />
                    <Route path="/signin/user" exact={true} render={(props) => <Signin role="Usuario"/>}/>
                    <Route path="/signin/driver" exact={true} render={(props) => <Signin role="Conductor"/>}/>
                    <Route path="/profile" exact={true} component = {Profile}/>
                    <Route component={NoMatch} />
                  </Switch>
                </div>
            </Router>
          </Provider>
        );
    }
}


function NoMatch({ location }) {
    return (
      <div>
        <h3>
          No se encuentra la ruta <code>{location.pathname}</code>
        </h3>
      </div>
    );
}


/*const ProtectedRoute 
  = ({ isAllowed, ...props }) => 
     isAllowed 
     ? <Route {...props}/> 
     : <Redirect to="/"/>;*/

export default Routes;