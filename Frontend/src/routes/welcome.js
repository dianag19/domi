import React, { Component } from 'react'
import '../App.css';
import Footer from '../components/footer'
import { connect } from 'react-redux'
import { withRouter } from 'react-router-dom'
//importo componente main
import Main from '../components/main'
import Servicios from '../components/services'
import Register from '../components/register'
//import { throws } from 'assert';


class Welcome extends Component {

  constructor(props){
    super(props);    

    const {authenticated} = this.props;

    if(authenticated.loggedIn){
      this.props.history.push('/profile');  
    }

  }

  render() {
    return (
      <div>
        
        <Main />
        <Servicios />
        <Register />
        <Footer></Footer>
      </div>
    );
  }
}

const mapStateToProps = state => ({
  ...state,
  authenticated: state.authenticated
});

export default withRouter(connect(mapStateToProps)(Welcome));