import React, { Component } from 'react'
import '../App.css';
import Form from 'react-bootstrap/Form'
import Button from 'react-bootstrap/Button'
import Modal from 'react-bootstrap/Modal'
import { connect } from 'react-redux'
import { withRouter } from 'react-router-dom'
import isAuthenticated from "../redux/actions/isAuthenticated";
import axios from 'axios'

class LoginForm extends React.Component {


    constructor(props, context) {
      super(props, context);
      this.log = this.log.bind(this);
      this.onChanged = this.onChanged.bind(this);
      this.state = {
        numText:'',
        passText:''  
      }
    }


    onChanged(event,name) {
        let textR = event.target.value
        switch(name){
            case 'numCel':
                return( 
                    this.setState({
                        numText: textR.replace(/[^0-9]/g, '')}))
            case 'pass':
                return(
                    this.setState({
                        passText: textR
                    })
                )                    
        }
      }



    log(){
      
      axios.post('http://localhost:3000/login',
      {
          num: this.state.numText,
          pass: this.state.passText
      }).then(res => {
          const {
            isAuthenticated,
            history, 
          } = this.props;
          isAuthenticated(res.data);
          history.push('/profile');
      }).catch((error) => {
          console.log(error.response);
      })

      this.setState({
        numText: '',
        passText: ''
      });
    }

    render() {
      return (
        <>
          <Modal show={this.props.showlog} onHide={this.props.closeLog}>
            <Modal.Header closeButton>
              <Modal.Title>Bienvenido</Modal.Title>
            </Modal.Header>
            <Modal.Body>
            <Form>
                    <Form.Group controlId="formBasicEmail">
                        <Form.Label>Num de celular</Form.Label>
                        <Form.Control placeholder="Digite su numero celular registrado" onChange={event => this.onChanged(event,'numCel')} value={this.state.numText}/>
                    </Form.Group>

                    <Form.Group controlId="formBasicPassword">
                        <Form.Label>Contraseña</Form.Label>
                        <Form.Control type="password" placeholder="Digite la contraseña" onChange={event => this.onChanged(event,'pass')} value={this.state.passText}/>
                    </Form.Group>
                    </Form>
            </Modal.Body>
            <Modal.Footer>
              <Button variant="secondary" onClick={this.props.closeLog}>
                Salir
              </Button>
              <Button variant="primary" onClick={this.log}>
                Iniciar sesión
              </Button>
            </Modal.Footer>
          </Modal>
        </>
      );
    }
  }

  const mapStateToProps = state => ({
      ...state
  });

  const mapDispatchToProps = {
    isAuthenticated
  };

export default withRouter(connect(mapStateToProps,mapDispatchToProps)(LoginForm));