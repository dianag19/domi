import React, { Component } from 'react';
import '../App.css';

//importo componentes para formulario
import Carousel from 'react-bootstrap/Carousel'
import { connect } from 'react-redux'

class Direcciones extends Component {

    //Propiedades
    constructor(props) {
        super(props);
        
    }


    render() {
        return (
            
            <Carousel>
            <Carousel.Item>
            <div className="App-box-services text-center">
            <i className="fas fa-map-marker fa-7x"></i>
            </div>
              <Carousel.Caption>
                <h3>Nombre dirección</h3>
                <p>Direccion</p>
              </Carousel.Caption>
            </Carousel.Item>
            <Carousel.Item>
            <div className="App-box-services text-center">
            <i className="fas fa-map-marker fa-7x"></i>
            </div>
              <Carousel.Caption>
                <h3>Nombre dirección</h3>
                <p>Direccion</p>
              </Carousel.Caption>
            </Carousel.Item>
           </Carousel>
        );
    }
}

const mapStateToProps = state => ({
    ...state
});


export default connect(mapStateToProps)(Direcciones);