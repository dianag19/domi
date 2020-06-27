import React, { Component } from 'react';
import '../App.css';

//importo componentes para formulario
import Container from 'react-bootstrap/Container'
import Row from 'react-bootstrap/Row'
import Col from 'react-bootstrap/Col'
import Form from 'react-bootstrap/Form'
import Button from 'react-bootstrap/Button'
import Card from 'react-bootstrap/Card'
import Modal from 'react-bootstrap/Modal'
import OverlayTrigger from 'react-bootstrap/OverlayTrigger'
import Tooltip from 'react-bootstrap/Tooltip'
import axios from 'axios'
import { connect } from 'react-redux';
import loginForm from '../redux/actions/loginForm'

class FormUser extends Component {

    //Propiedades
    constructor(props) {
        super(props);
        this.state = { 
            numText: '',
            nameText: '',
            lastNameText: '',
            creditText: '',
            passText: ''};
        this.onChanged = this.onChanged.bind(this);
        this.smShow = this.smShow.bind(this);
        this.smClose = this.smClose.bind(this);
        this.openForm = this.openForm.bind(this);
    }

    //Evento controlador de solo ingreso de números
    onChanged(event,name) {
        let textR = event.target.value;
        switch(name){
            case 'numCel':
                return( 
                    this.setState({
                        numText: textR.replace(/[^0-9]/g, '')}));

            case 'name':
                return(
                    this.setState({
                        nameText: textR   
                    })
                );
            case 'lastName':
                return(
                    this.setState({
                        lastNameText: textR        
                    })
                );
            case 'credit':
                return(
                    this.setState({
                        creditText: textR
                    })
                );
            case 'pass':
                return(
                    this.setState({
                        passText: textR
                    })
                )                    
        }
    }

    submitForm(e) {
        e.preventDefault();

        axios.post('http://localhost:3000/signin/user',
            {
                cel: this.state.numText,
                name: this.state.nameText,
                ap: this.state.lastNameText,
                tc: this.state.creditText,
                pass: this.state.passText
            }).then(res => {
            console.log(res);
            console.log(res.data);
        }).catch((error) => {
            console.log(error.response);
        });
        this.setState({
            smShow: false,
            numText: '',
            nameText: '',
            lastNameText: '',
            creditText: '',
            passText: ''
        });
        this.smShow();

    }

    smShow(){
        this.setState({
            smShow:true
        })
    }

    smClose(){
        this.setState({
            smShow:false
        });
        this.openForm();
    }

    openForm(){
        const { loginForm } = this.props;
        loginForm(true);
    }

    render() {
        return (
            <header className="App-header-signUser">
                <Modal
                    size="sm"
                    show={this.state.smShow}
                    onHide={this.smClose}
                    aria-labelledby="example-modal-sizes-title-sm"
                >
                    <Modal.Header closeButton>
                        <Modal.Title id="example-modal-sizes-title-sm">
                            Aviso
                        </Modal.Title>
                    </Modal.Header>
                    <Modal.Body>Se ha creado el usuario con exito. </Modal.Body>
                    <Modal.Footer>
                        <Button variant="primary" onClick={this.smClose}>
                            Ok
                        </Button>
                    </Modal.Footer>
                </Modal>
                <Container>
                    <Row>
                        <Col md={6} style={{textAlign: 'initial'}}>
                            <span style={{color: 'white', fontWeight: 'bold'}}></span><h1>Unete a nosotros</h1>
                            <p>Registra un par de datos personales y contraseña, y pide tu taxi ya mismo!</p>
                            <p>¡No esperes mas!</p>
                            <a href="#" onClick={this.openForm}>¿Ya tienes una cuenta?</a>
                        </Col>
                        <Col md={6}>
                            <Card text="info">
                                <Card.Header>Formulario de Usuario</Card.Header>
                                <Card.Body>
                                    <Form onSubmit={(e) => this.submitForm(e)}>
                                        <Form.Row>
                                            <Form.Group as={Col} controlId="FormGridName">
                                                <Form.Label>Nombre</Form.Label>
                                                <Form.Control placeholder="Inserte su nombre..."
                                                              onChange={event => this.onChanged(event, 'name')}
                                                              value={this.state.nameText}></Form.Control>
                                            </Form.Group>
                                            <Form.Group as={Col} controlId="FormGridLastName">
                                                <Form.Label>Apellidos</Form.Label>
                                                <Form.Control placeholder="Inserte sus apellidos..."
                                                              onChange={event => this.onChanged(event, 'lastName')}
                                                              value={this.state.lastNameText}></Form.Control>
                                            </Form.Group>
                                        </Form.Row>
                                        <Form.Row>
                                            <Form.Group as={Col} controlId="FormGriCel">
                                                <Form.Label>Num cel</Form.Label>
                                                <OverlayTrigger
                                                    overlay={<Tooltip id="tooltip-disabled">Este sera su nuevo usuario
                                                        dentro de la app</Tooltip>}>
                                                    <Form.Control onChange={event => this.onChanged(event, 'numCel')}
                                                                  value={this.state.numText}
                                                                  placeholder="Inserte numero de celular"></Form.Control>
                                                </OverlayTrigger>

                                            </Form.Group>
                                            <Form.Group as={Col} controlId="FormGridTc">
                                                <Form.Label>Tarjeta de credito </Form.Label>
                                                <Form.Control type="password"
                                                              placeholder="Inserte numero de tarjeta de credito"
                                                              onChange={event => this.onChanged(event, 'credit')}
                                                              value={this.state.creditText}></Form.Control>
                                            </Form.Group>
                                        </Form.Row>

                                        <Form.Group controlId="formGridAddress2">
                                            <Form.Label>Contraseña</Form.Label>
                                            <OverlayTrigger
                                                overlay={<Tooltip id="tooltip-disabled">Te recomendamos que crees una
                                                    contraseña de al menos 8 caracteres, símbolos y números</Tooltip>}>
                                                <Form.Control type="password" placeholder="Ingrese su contraseña"
                                                              onChange={event => this.onChanged(event, 'pass')}
                                                              value={this.state.passText}/>
                                            </OverlayTrigger>
                                        </Form.Group>
                                        <Button variant="outline-primary" type="submit">
                                            Iniciar
                                        </Button>
                                    </Form>
                                </Card.Body>
                            </Card>
                        </Col>
                    </Row>
                </Container>
            </header>


        );
    }
}


const mapDispatchToProps = {
    loginForm
};

const mapStateToProps = state => ({
    ...state,
    showlog: state.activarLogin
});

export default connect(mapStateToProps, mapDispatchToProps)(FormUser);

