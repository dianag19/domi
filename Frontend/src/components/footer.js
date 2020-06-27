import React, { Component } from 'react'
import '../App.css';

class Footer extends Component {
    render() {
        return(
            <footer className="App-footer">
            <div className="container text-center text-md-left">
            
        <div className="container text-center text-md-left">

            
            <div className="row">

                
                <div className="col-md-4 mx-auto">

                    
                <h5 className="font-weight-bold text-uppercase mt-3 mb-4">SOBRE NOSOTROS</h5>
                    <img src={process.env.PUBLIC_URL+"/assets/img/logoTaxi.png"}></img>
                    <p>
                        Conoce quienes nos apoyan, el equipo de trabajo y mucho más en los siguientes enlaces.     
                    </p>

                </div>
                

                <hr className="clearfix w-100 d-md-none" />

                
                <div className="col-md-2 mx-auto">

                    
                    <h5 className="font-weight-bold text-uppercase mt-3 mb-4">Patrocinadores</h5>

                    <ul className="list-unstyled">
                        <li>
                            <a href="#!">Transito</a>
                        </li>
                        <li>
                            <a href="#!">CaliViveDigital</a>
                        </li>
                    </ul>

                </div>
                

                <hr className="clearfix w-100 d-md-none" />

                
                <div className="col-md-2 mx-auto">

                   
                    <h5 className="font-weight-bold text-uppercase mt-3 mb-4">Convenios</h5>

                    <ul className="list-unstyled">
                        <li>
                            <a href="#!">Univalle</a>
                        </li>
                        <li>
                            <a href="#!">CAM</a>
                        </li>
                    </ul>

                </div>
                

                <hr className="clearfix w-100 d-md-none" />

                
                <div className="col-md-2 mx-auto">

                    
                    <h5 className="font-weight-bold text-uppercase mt-3 mb-4">Equipo</h5>

                    <ul className="list-unstyled">
                        <li>
                            <a href="#!">Al3X</a>
                        </li>
                        <li>
                            <a href="#!">Diana</a>
                        </li>
                        <li>
                            <a href="#!">David</a>
                        </li>
                    </ul>

                </div>
                

            </div>
            

        </div>
        

            </div>
        </footer>
        );    
    }
}

export default Footer;
