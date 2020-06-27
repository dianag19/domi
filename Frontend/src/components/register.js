import React, { Component } from 'react';
import '../App.css';

//importo componentes para formulario
import Container from 'react-bootstrap/Container'
import Row from 'react-bootstrap/Row'
import Col from 'react-bootstrap/Col'
import Form from 'react-bootstrap/Form'
import Button from 'react-bootstrap/Button'
import Card from 'react-bootstrap/Card'
import OverlayTrigger from 'react-bootstrap/OverlayTrigger'
import Tooltip from 'react-bootstrap/Tooltip'


class Register extends Component {

    render() {
        return (
            <header id="registro" className="App-header-register">
                <Container>
                    <Row>
                        <Col md={12}>
                            <h2 className="text-center">FORMULARIOS DE REGISTRO</h2>
                        </Col>
                    </Row>

                    <Row>
                        <Col md={6}>
                            <div className="App-box-services text-center">
                                <i className="fas fa-user fa-7x"></i>
                                <h2>Usuario</h2>
                                <p>Registrate para viajar</p>
                                <Button href="/signin/user" variant="primary">Registrarme</Button>
                            </div>
                        </Col>
                        <Col md={6}>
                            <div className="App-box-services text-center">
                                <i className="fas fa-taxi fa-7x"></i>
                                <h2>Conductor</h2>
                                <p>Registrate para conducir</p>
                                
                                <Button href="/signin/driver" variant="warning">Registrarme</Button>
                            </div>
                        </Col>
                    </Row>
                </Container>
            </header >
        );
    }
}
export default Register;