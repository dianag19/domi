import React, { Component } from 'react';
import '../App.css';

//importo componentes para formulario
import Container from 'react-bootstrap/Container'
import Row from 'react-bootstrap/Row'
import Col from 'react-bootstrap/Col'


class Main extends Component {

    render() {
        return (

            <header className="App-header-main">
                <Container>
                    <Row>
                        <Col md={6}>
                            <h1>NotThatEasyTaxy</h1>
                            <h3>Ahora viajar y conducir es más fácil</h3>
                        </Col>
                        <Col md={6}>
                            
                        </Col>
                    </Row>
                </Container>
            </header>
        );
    }
}

export default Main;
