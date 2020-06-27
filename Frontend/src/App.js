import React, { Component } from 'react';
import './App.css';
import Routes from './router'

import Navbar from 'react-bootstrap/Navbar'
import Brand from 'react-bootstrap/NavbarBrand'
import Nav from 'react-bootstrap/Nav'
import Link from 'react-bootstrap/NavLink'
import Button from 'react-bootstrap/Button'
import ButtonGroup from 'react-bootstrap/ButtonGroup'
import LoginForm from './components/loginForm'
//importo barra de navegación negra
import  NavbarBlack from './components/navbarBlack';


class App extends Component {
  render() {
    return (
      <div className="App">
        <Routes></Routes>
      </div>
    );
  }
}

export default App;
