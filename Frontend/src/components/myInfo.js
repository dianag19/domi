import React, { Component } from 'react'
import '../App.css';
import Form from 'react-bootstrap/Form'
import Button from 'react-bootstrap/Button'
import Modal from 'react-bootstrap/Modal'
import Row from 'react-bootstrap/Row'
import Col from 'react-bootstrap/Col'
import ButtonGroup from 'react-bootstrap/ButtonGroup'
import { connect } from 'react-redux'
import showInfoAction from '../redux/actions/showInfoAction'

class myInfo extends React.Component {


  constructor(props, context) {
    super(props, context);
    this.handleClose = this.handleClose.bind(this);
  }


  handleClose() {
    const {showInfoAction} = this.props;
    showInfoAction(false,{});    
  }


  render() {
    const {showInfo} = this.props;
    console.log(showInfo.data[0]);   
    return (
        <>
        <Modal
          size="lg"
          show={this.props.showInfo.show}
          onHide={this.handleClose}
        >
          <Modal.Header closeButton>
            <Modal.Title>Perfil</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <Form>
              <div>
                <Row>
                  <Col md={12}>
                    <Row>
                      <Col md={3}>
                        <i className="fas fa-user fa-7x"></i>
                      </Col>
                      <Col md={6}>
                        <Form.Group as={Row}>
                          <Form.Label column sm="3">Usuario:</Form.Label>
                          <Col sm="9">
                          <Form.Label column sm="3">{showInfo.data[0] ? `${showInfo.data[0].nombre_completo}`: "ERROR"}</Form.Label>
                          </Col>
                        </Form.Group>
                        <Form.Group as={Row}>
                          <Form.Label column sm="3">Km recorridos: </Form.Label>
                          <Col sm="9">
                          <Form.Label column sm="3">{showInfo.data[0] ? `${showInfo.data[0].distancia_total_viajada}`: "ERROR"}</Form.Label>
                          </Col>
                        </Form.Group>

                        <Form.Group as={Row} controlId="formPlaintextEmail">
                          <Form.Label column sm="3">Teléfono: </Form.Label>
                          <Col sm="9">
                            <Form.Label column sm="3">{showInfo.data[0] ? `${showInfo.data[0].numero_de_celular}`: "ERROR"}</Form.Label>
                          </Col>
                        </Form.Group>
                        <Form.Group as={Row} controlId="formPlaintextEmail">
                          <Form.Label column sm="3">Numero de viajes: </Form.Label>
                          <Col sm="9">
                            <Form.Label column sm="3">{showInfo.data[0] ? `${showInfo.data[0].numero_de_viajes}`: "ERROR"}</Form.Label>
                          </Col>
                        </Form.Group>
                        <Form.Group as={Row} controlId="formPlaintextEmail">
                          <Form.Label column sm="3">Deuda</Form.Label>
                          <Col sm="9">
                            <Form.Label column sm="3">{showInfo.data[0] ? `${showInfo.data[0].deuda}`: "ERROR"}</Form.Label>
                          </Col>
                        </Form.Group>
                      </Col>
                      <Col md={3}>

                        <ButtonGroup vertical>
                          <Button variant="secondary"><i className="fas fa-cog fa-4x"></i>
                            Modificar</Button>
                          <Button variant="warning">
                            <i className="fas fa-trash-alt fa-4x"></i>
                            Eliminar cuenta</Button>
                          </ButtonGroup>
                          

                      </Col>
                    </Row>
                  </Col>
                </Row>
              </div>
            </Form>
          </Modal.Body>
            <Modal.Footer>
              <Button variant="secondary" onClick={this.handleClose}>
                Salir</Button>
            </Modal.Footer>
        </Modal>
      </>
        );
      }
    }

    const mapStateToProps = state => ({
        ...state,
        showInfo: state.showInfo
    });
    
    const mapDispatchToProps = {
        showInfoAction
    };


    
export default connect(mapStateToProps,mapDispatchToProps)(myInfo);